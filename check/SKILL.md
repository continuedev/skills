---
name: check
description: Runs .continue/checks locally against the current diff or plan. Auto-detects mode — in plan mode it reviews the plan, otherwise it reviews the git diff. Use when the user says /check.
---

# Unified Check Runner

Run relevant `.continue/checks/*.md` checks against either the current **git diff** (before pushing) or the current **implementation plan** (before coding). The mode is auto-detected.

## Workflow

### 1. Detect mode

- **Plan mode**: If you are currently in plan mode (plan mode system message is present), this is a **plan check**. Determine the plan file path from the plan mode system message.
- **Diff mode**: Otherwise, this is a **diff check**.

### 2. Pre-flight (diff mode only)

For diff mode, verify there are actual changes to check:
- Run `git diff main...HEAD` — if empty, also try `git diff --cached` and `git diff`.
- If there are no changes at all, tell the user and stop.

### 3. Run checks via shell script

Tell the user which mode was detected and that the following checks will run: architecture-boundaries, code-conventions, database-migrations, security, telemetry-integrity, test-quality, typeorm-cascade-check, terraform-env-vars, mobile-layout (only those that exist as `.continue/checks/*.md` files).

Then run a single **foreground** Bash command with a generous timeout (5 minutes / 300000ms):

**Plan mode:**
```bash
bash {absolute path to .claude/skills/check/run-checks.sh} --mode plan {plan-file-path}
```

**Diff mode:**
```bash
bash {absolute path to .claude/skills/check/run-checks.sh} --mode diff
```

Progress lines will stream live. Full detailed results are written to `/tmp/check-results.txt`.

### 4. Parse results

Read `/tmp/check-results.txt`. It contains `=== check-name ===` sections, each with a PASS or FAIL verdict and findings.

### 5. Summarize results

Present a summary table:

```
| Check | Result |
|-------|--------|
| ✅ Code Conventions | Passed |
| ❌ Security | 2 errors, 1 warning |
| ✅ Test Quality | Passed |
| ⚠️ Mobile Layout | 1 warning |
| ... | ... |
```

Use these emojis:
- ✅ = all clear, no findings
- ❌ = has Error-severity findings
- ⚠️ = has Warning-severity findings but no errors

### 6. Act on results (mode-dependent)

#### Plan mode

1. **For obvious fixes** (e.g., plan forgot to mention a migration, missing a security step that's clearly needed): directly update the plan to incorporate the fix. Tell the user what you changed and why.

2. **For ambiguous findings** (e.g., the check raises a valid architectural question with multiple possible answers): use `AskUserQuestion` to present the issue and let the user decide before updating the plan. Include:
   - The check name as the header
   - A concise description of the concern
   - Options for how to resolve it in the plan

3. After all findings are addressed, present the updated plan to the user for final approval via `ExitPlanMode`.

#### Diff mode

Do NOT dump all failure details in a big block. Instead, use `AskUserQuestion` to present each failed check's findings and let the user decide what to do.

For each check that has findings, present ONE AskUserQuestion with:
- The check name as the header
- A concise description of the finding(s) in the question text
- Options like:
  - "Fix it" — you will fix the issue
  - "Skip" — ignore this finding
  - (Add other options if contextually appropriate, e.g. "Add to backlog")

You can batch multiple failed checks into a single AskUserQuestion call (one question per failed check, up to 4 per call). If there are more than 4 failed checks, use multiple AskUserQuestion calls.

Then execute whatever the user chose — fix the issues they said to fix, skip the ones they said to skip.
