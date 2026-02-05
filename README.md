# Continue Skills

Reusable skills for Claude Code and other AI agents.

## Install

```bash
# Install a specific skill
npx skills add continuedev/skills --skill <name>

# Install all skills
npx skills add continuedev/skills --all
```

## Skills

| Skill | Description |
|-------|-------------|
| **all-green** | Gets a PR to a mergeable state by addressing review comments, resolving merge conflicts, and fixing failing CI checks. |
| **scan** | Audits a codebase against another skill's criteria using a parallel agent team, producing a structured findings report with optional automated fixes. |
