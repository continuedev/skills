# Continue Skills

Reusable skills for Claude Code and other AI agents.

## check

Runs checks locally against your current diff, simulating the GitHub PR checks experience. Use `/check` in your coding agent to review changes before pushing.

```bash
npx skills add continuedev/skills --skill check
```

## writing-checks

Teaches your agent how to write Continue check files — markdown-defined AI agents that review pull requests.

```bash
npx skills add continuedev/skills --skill writing-checks
```

## all-green

Gets a PR to a mergeable state by addressing review comments, resolving merge conflicts, and fixing failing CI checks.

```bash
npx skills add continuedev/skills --skill all-green
```

## scan

Audits a codebase against another skill's criteria using a parallel agent team, producing a structured findings report with optional automated fixes.

```bash
npx skills add continuedev/skills --skill scan
```
