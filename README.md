<p align="center">
  <h1 align="center">🧱 VibeStack</h1>
  <p align="center">
    <strong>Give your AI agents the context to build, not just guess.</strong>
    <br />
    Opinionated files, skills, and tooling that keep AI agents effective as your codebase grows.
    <br />
    No dependencies. No lock-in. Just markdown and a shell script.
  </p>
  <p align="center">
    <a href="https://github.com/tylerthebuildor/vibestack">GitHub</a> · <a href="https://vibestack.md">Website</a>
  </p>
</p>

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/install.sh | bash
```

Run from the root of your project. Existing files are never overwritten.

Then run `/vibestack` inside Claude Code to auto-fill everything for your project.

---

## What You Get

Five files:

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Quick-start reference card — tells any contributor (human or AI) what this project is, how it's built, how to work in it |
| `TODO.md` | Lightweight task tracker with a protocol for parallel work so agents don't collide |
| `ops.sh` | Single entry point for build, test, run, deploy — `./ops.sh build`, `./ops.sh test`, `./ops.sh deploy prod` |
| `docs/` | Living knowledge base — the docs you write today prevent your AI from re-discovering the same lessons tomorrow |
| `.claude/skills/` | Teach AI your project's conventions and workflows via reusable skills |

## Skills

| Command | What it does |
|---------|-------------|
| `/vibestack` | Analyzes your project and fills out CLAUDE.md, ops.sh, docs, and TODO.md with project-specific content |
| `/squad` | Generates domain-specific rules and specialist subagents so Claude auto-loads the right context per file |
| `/todo` | Works through TODO.md tasks sequentially. `/todo populate` seeds the next batch ranked by impact |
| `/docs` | Captures conversation learnings into your docs folder and cleans up stale content |

Also includes `cli-first` — a reference skill that teaches your AI to use platform CLIs and check `.env*` files instead of making raw API calls.

---

## Extras

### CI Guards

Reusable GitHub Actions workflows: lint, test coverage, security scans, code smell checks on every PR. Supports Node/TypeScript, Python, Rust, and Go.

```bash
curl -fsSL https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit/extras/ci-guards/install.sh | bash -s -- <language>
```

### Dev Tools Installer

One-pass installer for platform CLIs (aws, vercel, etc.) — giving your AI agent direct infrastructure access from the terminal.

**macOS / Linux / WSL:**

```bash
curl -fsSL https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit/extras/dev-tools/install.sh | bash
```

**Windows:** Run the bootstrap script first to set up WSL + Ubuntu:

```powershell
# PowerShell (as Administrator)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit/extras/dev-tools/bootstrap-windows.ps1" -OutFile "$env:TEMP\bootstrap-windows.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\bootstrap-windows.ps1"
```

### The `claw` Alias

The dev-tools installer offers to add `claw` to your shell — an alias for `claude --permission-mode bypassPermissions --`. Use it anywhere to run Claude uninterrupted.

```bash
claw "refactor the auth module to use JWT"
```

---

## Opinions

This is what makes VibeStack different. The conventions above give your project structure — the opinions below are why.

### Bypass Permissions

VibeStack ships with all Claude Code tool permissions pre-approved. No "can I run this command?" prompts. Permission prompts kill flow and add no real safety. Code quality enforcement belongs in your CI pipeline and pre-commit hooks, not in an interactive approval flow.

### Squad Mode

Large codebases overwhelm AI context windows. `/squad` analyzes your project and breaks it into logical domains — each getting its own path-specific rules (`.claude/rules/`) and optionally a specialist subagent (`.claude/agents/`). When Claude touches a file in the auth domain, it automatically loads auth-specific conventions. Run `/squad` once after setup, then `/squad refresh` as your project grows.

### CI Over Approval Gates

AI agents write bad code sometimes. The answer isn't slowing your agent down — it's a CI pipeline that catches problems automatically. Bypass mode + CI Guards = maximum speed with maximum accountability.

### Finish Notification

When Claude finishes a task, your machine plays a chime and announces the project name out loud (macOS `say`, Linux `espeak`). Kick off a task, walk away, get an audio alert when it's done.

---

## Philosophy

**Opinionated but not intrusive.** Strong opinions about structure, zero lock-in. It's just files — delete them and move on.

**Conventions over configuration.** No settings files to learn. Fill in templates, the conventions do the rest.

**AI agents are team members.** Everything is written for both humans and AI. Your assistant is a first-class contributor that needs context to do good work.

**CLI over dashboard.** Every major platform ships a CLI. Installing them gives your AI agent superpowers.

**Bypass mode over permission prompts.** Let the agent work. Review the output. Catch issues at commit and deploy time.

**Scale through structure.** A weekend project doesn't need this. But the moment your project outgrows a single prompt, structure is what keeps AI effective.

---

<p align="center">
  <strong>Stop vibing into chaos. Start vibing with structure.</strong> ✨
  <br /><br />
  MIT License
</p>
