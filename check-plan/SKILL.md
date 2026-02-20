---
name: check-plan
description: Runs .continue/checks against the current implementation plan, reviewing it for potential issues before implementation begins. Use when in plan mode and the user says /check-plan.
---

# Plan Review with Agent Checks

Run relevant `.continue/checks/*.md` checks against the current implementation plan, catching architectural, security, and convention issues before any code is written.

## Workflow

### 1. Capture the plan

- Read the current plan file that was written during plan mode. It will be at the path shown in the plan mode system message (typically `~/.claude/todos/plan.md` or similar).
- If you cannot find or determine the plan file path, ask the user to paste or point to their plan.
- Write the plan contents to `/tmp/check-plan.md` so sub-agents can read it without the plan being loaded into each agent's prompt.
- **Do NOT read the plan back into your own context after writing it.** You already have it.

### 2. Discover relevant checks

Glob `.continue/checks/*.md` to find all check files, then **filter to only these plan-relevant checks**:

- `architecture-boundaries.md`
- `code-conventions.md`
- `database-migrations.md`
- `security.md`
- `telemetry-integrity.md`
- `test-quality.md`
- `typeorm-cascade-check.md`
- `terraform-env-vars.md`
- `mobile-layout.md`

**Skip** checks that require a real diff or take actions (these only make sense post-implementation):
- `ai-merge.md`, `blog-writer.md`, `geo.md`, `implement-todos.md`, `pr-description-coverage.md`, `pr-screenshots.md`, `staging-qa.md`, `preview-qa.md`, `ui-tests.md`

Present the user with the list of checks that will run, then proceed immediately without waiting.

### 3. Run all checks in parallel via shell script

Run all checks with a single Bash command using the `run-checks.sh` script bundled with this skill. The script spawns parallel `claude -p` processes (one per check) and outputs all results together.

```bash
{absolute path to .claude/skills/check-plan/run-checks.sh} \
  /tmp/check-plan.md \
  {absolute path to .claude/skills/check-plan/references/review-prompt.md} \
  {absolute path to .continue/checks/check1.md} \
  {absolute path to .continue/checks/check2.md} \
  ...
```

This runs in the background (`run_in_background: true` on the Bash tool) with a generous timeout (5 minutes / 300000ms). The output contains `=== check-name ===` sections, each starting with PASS or FAIL.

### 4. Parse results

Read the Bash output. For each `=== check-name ===` section, extract whether it says PASS or FAIL and note any findings.

### 5. Act on results

**This is different from /check** — instead of presenting an interactive triage, directly update the plan:

1. **Summarize** findings in a brief table:
   ```
   | Check | Result |
   |-------|--------|
   | ✅ Code Conventions | Passed |
   | ❌ Security | Missing auth middleware on new endpoint |
   | ✅ Test Quality | Passed |
   | ⚠️ Database Migrations | Plan should mention migration for new column |
   ```

2. **For obvious fixes** (e.g., plan forgot to mention a migration, missing a security step that's clearly needed): directly update the plan to incorporate the fix. Tell the user what you changed and why.

3. **For ambiguous findings** (e.g., the check raises a valid architectural question with multiple possible answers): use `AskUserQuestion` to present the issue and let the user decide before updating the plan. Include:
   - The check name as the header
   - A concise description of the concern
   - Options for how to resolve it in the plan

4. After all findings are addressed, present the updated plan to the user for final approval via `ExitPlanMode`.
