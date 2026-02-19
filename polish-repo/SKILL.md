---
name: polish-repo
description: Polish an open-source repository with branding, community files, README overhaul, OG card, usage skill, PR checks, and publishing setup. Designed as a reusable template for Continue repos.
metadata:
  author: continuedev
  version: "1.0.0"
---

# Polish Repository

You are polishing an open-source repository to production quality. Follow each step in order, adapting to the project's language, ecosystem, and existing state.

## Step 1: Gather context

Before making any changes, understand what you're working with:

1. **Read the package manifest** — `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, etc. Note the project name, description, license field, and any existing scripts.
2. **Check for CI workflows** — look in `.github/workflows/` for existing build, test, and release pipelines.
3. **Check for branding assets** — look for banner images, logos, or OG cards in `.github/assets/`, `public/`, or the repo root. If none exist, download the shared Continue banner from `https://raw.githubusercontent.com/continuedev/continue/main/media/github-readme.png` and save it as `.github/assets/continue-banner.png`.
4. **Determine ecosystem** — npm/Node.js, Go, Rust, Python, etc. This affects publishing setup and contributing instructions.
5. **Read the existing README** — understand what documentation already exists so you preserve and improve it rather than losing content.
6. **Check for existing community files** — `LICENSE`, `CONTRIBUTING.md`, `SECURITY.md`, issue templates, PR templates.

## Step 2: README overhaul

Restructure the README with this template:

```markdown
<p align="center">
  <a href="https://continue.dev">
    <img src=".github/assets/continue-banner.png" width="800" alt="Continue" />
  </a>
</p>

<h1 align="center">{project-name}</h1>

<p align="center">{one-line description}</p>

---

## Why?

[Before/after comparison or 2-3 sentences explaining the problem this solves]

## Table of Contents

[Links to all sections]

## Quick start
[Existing quick start content — preserve and improve]

[... all existing documentation sections ...]

## Contributing
[Link to CONTRIBUTING.md]

## License
[Link to LICENSE with copyright line]

---

<p align="center">Built by <a href="https://continue.dev">Continue</a></p>
```

Key principles:
- **No shields.io badges** — keep the header clean
- **Preserve all existing content** — don't lose documentation, just restructure
- **Add a "Why?" section** — show the before/after or explain the value proposition concisely
- **Add TOC** — for any README with more than 5 sections
- **Add Contributing + License sections** at the bottom

## Step 3: Community files

Create these files in `.github/` (skip any that already exist and are adequate):

### LICENSE (repo root)

If missing, create `LICENSE` at the repo root matching the `license` field in the package manifest. For MIT:

```
MIT License

Copyright (c) 2025 Continue Dev, Inc.

[standard MIT text]
```

### CONTRIBUTING.md

Include:
- Dev setup instructions (clone, install, build, test)
- Project structure overview
- Conventional Commits convention (`feat:`, `fix:`, `docs:`, etc.)
- PR process
- Link to bug report template

### SECURITY.md

Include:
- Report to **security@continue.dev**
- 48-hour acknowledgment SLA
- Scope section specific to the project's attack surface (e.g., SSRF for fetch-based tools, injection for template engines)
- Out-of-scope items (upstream dependencies, requires existing access)

### Issue templates (`.github/ISSUE_TEMPLATE/`)

**`bug_report.yml`** — YAML form with:
- Version input
- Environment/framework version input
- Relevant dropdown (project-specific — e.g., detection method for next-geo, platform for CLI tools)
- Description textarea
- Repro steps textarea
- Logs textarea (with `render: shell`)

**`feature_request.yml`** — YAML form with:
- Problem textarea
- Proposed solution textarea
- Alternatives considered textarea

**`config.yml`** — Disable blank issues:
```yaml
blank_issues_enabled: false
```

### PULL_REQUEST_TEMPLATE.md

```markdown
## Description

<!-- What does this PR do? Why? -->

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Refactor
- [ ] Other (describe below)

## Checklist

- [ ] Tests added/updated
- [ ] Types are correct
- [ ] Commit messages follow Conventional Commits
- [ ] README updated (if applicable)
```

### release.yml

Categorize GitHub release notes:

```yaml
changelog:
  categories:
    - title: New Features
      labels:
        - enhancement
    - title: Bug Fixes
      labels:
        - bug
    - title: Documentation
      labels:
        - documentation
    - title: Other
      labels:
        - "*"
```

### What to skip

- **FUNDING.yml** — Continue is VC-backed, not seeking sponsorships
- **CODE_OF_CONDUCT.md** — Only add if the project has an active community with multiple external contributors

## Step 4: OG card

Create `.github/assets/og-card.html` — a self-contained 1280x640 HTML file that can be screenshotted for the GitHub social preview.

Copy one of the hero background images from Continue's shared assets (`heroBackground/` in the website repo) into `.github/assets/` to use as a subtle ambient element.

**Design — match the continue.dev/home cleanroom aesthetic:**
- **Background:** Off-white (`hsl(0 0% 95.3%)`) matching the homepage
- **Ambient image:** Position the hero background image in the top-right at very low opacity (~12%) with a slight blur, as a soft prismatic glow — not as a full-bleed background
- **Typography:** IBM Plex Sans (light 300 weight for the title, regular 400 for tagline) + IBM Plex Mono (400 for labels and the install command). Load from Google Fonts.
- **Title:** Large (~80px), light weight, tight tracking (-2px), color `rgba(0,0,0,0.88)`
- **Tagline:** Below the title, ~24px, `rgba(0,0,0,0.4)`
- **Label:** Small monospace "CONTINUE" label above the title, uppercase, wide tracking (0.2em), `rgba(0,0,0,0.3)`
- **Install pill:** Monospace install command (e.g., `npm install {package}`) in a pill with `rgba(0,0,0,0.04)` background and `rgba(0,0,0,0.06)` border — matching the homepage's chip/input style
- **Footer:** Thin rule (`rgba(0,0,0,0.06)`) near the bottom, Continue logo at reduced opacity on the left, `continue.dev` in small monospace on the right
- **Overall feel:** Clean, minimal, generous whitespace, Swiss-inspired — premium but not flashy

Reference implementation: `next-geo/.github/assets/og-card.html`

After creating, instruct the user to:
1. Open the HTML file in a browser
2. Screenshot at 1280x640
3. Upload as the repo's social preview in Settings → General → Social preview

## Step 5: Usage skill

Create a `skill/SKILL.md` that walks a coding agent through installing and using the package/tool in their project. This is the "how do I adopt this?" guide.

Reference example: `next-geo/skill/SKILL.md`

The skill should:
- Have YAML frontmatter with `name`, `description`, and `metadata` (author, version)
- Include prerequisites and environment checks
- Walk through installation step by step
- Cover configuration and integration with existing code
- Include optional advanced steps
- End with verification steps
- Include a troubleshooting section

## Step 6: PR checks

Create `.continue/checks/` with project-specific checks. These checks run on PRs and flag issues that require human judgment — things linters can't catch.

Point the user to [continue.dev/walkthrough](https://continue.dev/walkthrough) for the full guide on writing checks.

Reference example: `next-geo/check/geo.md`

Good checks target:
- Content consistency (e.g., page.md files staying in sync with page.tsx)
- API contract changes that might break consumers
- Configuration changes that affect behavior
- Missing documentation for new features
- Security-sensitive changes

Bad checks (avoid — linters handle these):
- Code style
- Import ordering
- Type errors
- Test coverage thresholds

## Step 7: Publishing setup

If the project will be published to a package registry, set up automated releases.

### For npm packages

See [publishing-npm.md](publishing-npm.md) for the full reference.

Summary:
1. Install semantic-release and plugins as devDependencies
2. Create `release.config.cjs`
3. Create `.github/workflows/release.yaml` with OIDC-based npm publishing
4. Ensure `package.json` has correct `name`, `version`, `repository`, `files`, and `exports`

### For Go CLI tools

See [publishing-go.md](publishing-go.md) for the full reference.

Summary:
1. Create `.goreleaser.yml` with cross-platform build config
2. Create `.github/workflows/release.yml` triggered on `v*` tags
3. Set up version injection via ldflags
4. Document the release process (`git tag v1.0.0 && git push origin v1.0.0`)

## Step 8: Postinstall message (npm packages)

For npm packages that have a companion skill, add a postinstall script that tells users how to get started with a coding agent. This runs after `npm install` and prints a short message.

Create `scripts/postinstall.js`:

```js
#!/usr/bin/env node

// Skip during CI or global installs
if (process.env.CI || process.env.npm_config_global) {
  process.exit(0);
}

const name = "{package-name}";
const skill = "{skill-name}";
const org = "continuedev/skills";

console.log();
console.log(`  ${name} installed.`);
console.log();
console.log(`  Get started with a coding agent:`);
console.log(`    npx skills add ${org} --skill ${skill}`);
console.log();
console.log(`  Then ask your agent: "Set up ${name} in this project."`);
console.log();
```

Then update `package.json`:
- Add `"postinstall": "node scripts/postinstall.js || true"` to `scripts` (the `|| true` prevents install failures if the script errors)
- Add `"scripts"` to the `files` array so it's included in the published package

Key principles:
- **Keep it short** — 5 lines max, no ASCII art, no color codes
- **Fail silently** — use `|| true` so the postinstall never blocks installation
- **Skip in CI** — check `process.env.CI` to avoid noise in automated environments
- **One clear action** — the `npx skills add` command is the main CTA

Reference implementation: `next-geo/scripts/postinstall.js` and `next-geo/package.json`

## Step 9: Manual GitHub settings checklist

After all files are committed and pushed, instruct the user to configure these settings manually in the GitHub UI:

- [ ] **Description** — Set the repo description to match the README tagline
- [ ] **Website** — Set to `https://continue.dev` or the project's docs URL
- [ ] **Topics** — Add relevant topics (e.g., `nextjs`, `markdown`, `llm`, `content-negotiation`)
- [ ] **Social preview** — Upload the screenshot of `og-card.html`
- [ ] **Branch protection** — Require PR reviews and status checks on `main`
