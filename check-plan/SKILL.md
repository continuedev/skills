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

### 3. Run checks in parallel (background agents)

For each relevant check file, spawn a sub-agent with these settings:
- `subagent_type: "general-purpose"`
- `model: "haiku"` (fast and cheap for review tasks)
- `run_in_background: true`

Use this prompt structure (2 lines — the sub-agent reads its full instructions from disk):

```
Review the implementation plan at /tmp/check-plan.md against the check at {absolute path to .continue/checks/xxx.md}.
Read your detailed review instructions from: {absolute path to .claude/skills/check-plan/references/review-prompt.md}
```

Launch ALL sub-agents in a single message (all Task tool calls together).

### 4. Collect results efficiently

After launching all agents, wait for them to complete by reading their output files. **Do NOT read full outputs into your context.** Instead:

- For each background agent, use Bash to read just the last 30 lines of its output file: `tail -30 {output_file}`
- Parse whether it says PASS or FAIL and extract the key findings.

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
