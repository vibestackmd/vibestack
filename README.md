<p align="center">
  <h1 align="center">🌈 Vibestack</h1>
  <p align="center">
    <strong>A project convention kit for AI-assisted development.</strong>
    <br />
    Drop a small set of opinionated files into any project to help both you and your AI agents work effectively as the codebase grows.
    <br />
    No dependencies. No lock-in. Just markdown and a shell script.
  </p>
  <p align="center">
    <a href="#-the-conventions">Conventions</a> · <a href="#-the-opinions">Opinions</a> · <a href="#-philosophy">Philosophy</a>
  </p>
</p>

### Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/install.sh | bash
```

> Run from the root of your project. Project files are never overwritten. Vibestack-managed files (skills, hooks) prompt to update if upstream changes are available.

---

## 😤 The Problem

AI coding assistants are powerful — until your project grows. Context windows get overwhelmed, institutional knowledge lives in your head instead of your repo, and every project reinvents the same scaffolding. Vibestack gives your project a structure that scales for both human and AI contributors.

## 📦 The Conventions

Five files. That's it.

```
📋 CLAUDE.md              # Quick-start reference card for the project
✅ TODO.md                # Lightweight task tracker for human/AI collaboration
⚡ ops.sh                 # Single entry point for build, test, run, deploy
📚 docs/                  # Living documentation — your project's knowledge base
🧠 .claude/skills/        # Teach AI your project's conventions and workflows
```

**CLAUDE.md** — A structured overview that tells any contributor (human or AI) what this project is, how it's built, and how to work in it. Fill in the blanks and every AI session starts with the right context.

**docs/** — A knowledge base with conventions for when and how to write documentation. The docs you write today prevent your AI from re-discovering the same hard lessons tomorrow.

**TODO.md** — A dead-simple task file with a protocol for parallel work. Mark items pending before starting so parallel agents don't collide. No external tools needed.

**ops.sh** — One script for every project operation. Both humans and AI run `./ops.sh build`, `./ops.sh test`, `./ops.sh deploy prod`. Fill in your commands once and every contributor knows how to operate the project.

**.claude/skills/** — Reference skills auto-load as background knowledge (error handling patterns, API conventions). Task skills are repeatable workflows triggered via slash commands (`/deploy-staging`, `/audit-module src/auth`). Write a convention once, your AI follows it forever. Ships with a `cli-first` skill that teaches your AI to use platform CLIs and check `.env*` files instead of making raw API calls. The `/squad` skill analyzes your project and generates domain-specific rules and specialist subagents — so Claude automatically loads the right context for each part of your codebase. The `/todo` skill works through TODO.md tasks sequentially, and `/todo populate` re-analyzes the codebase to seed the next batch of highest-impact tasks ranked by production readiness.

## 🔥 The Opinions

This is what makes Vibestack different. The conventions above give your project structure — the opinions below are how we think AI-assisted development should actually work.

### 🚀 Bypass Permissions

Vibestack ships with all Claude Code tool permissions pre-approved. No "can I run this command?" prompts. No "can I edit this file?" gates. Your AI agent should run uninterrupted — permission prompts kill flow and add no real safety. Code quality enforcement belongs in your CI pipeline and pre-commit hooks, not in an interactive approval flow that breaks your agent's momentum every 30 seconds.

### 🐾 The `claw` Alias

The [dev-tools installer](#-dev-tools-installer) offers to add `claw` to your shell — an alias for `claude --permission-mode bypassPermissions --`. Use it anywhere, even outside Vibestack projects, to run Claude the way it's meant to be run: uninterrupted.

```bash
claw "refactor the auth module to use JWT"
```

### 🧠 Squad Mode

Large codebases overwhelm AI context windows. `/squad` fixes this by analyzing your project and breaking it into logical domains — each getting its own path-specific rules (`.claude/rules/`) and optionally a specialist subagent (`.claude/agents/`). When Claude touches a file in the auth domain, it automatically loads auth-specific conventions. When it works on the data layer, it gets data layer context. No manual switching required.

Run `/squad` once after setup, then `/squad refresh` as your project grows. Vibestack also enables Claude Code's experimental Agent Teams — Claude can spin up parallel specialists that coordinate on complex cross-cutting changes.

### 🛡️ CI Guards

Here's the uncomfortable truth: AI agents write bad code sometimes. Insecure code. Untested code. The answer isn't slowing your agent down with approval gates — it's a CI pipeline that catches problems automatically. Vibestack ships reusable GitHub Actions workflows that enforce lint, test coverage, security scans, and code smell checks on every PR. Supports Node/TypeScript, Python, Rust, and Go.

```bash
curl -fsSL https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit/extras/ci-guards/install.sh | bash -s -- <language>
```

Bypass mode + CI Guards = maximum speed with maximum accountability.

### 🔔 Finish Notification

When Claude finishes a task, your machine plays a chime and announces the project name out loud (macOS `say`, Linux `espeak`). Kick off a task, walk away, get a friendly audio alert when it's done. No more checking back every few minutes to see if Claude is waiting for you.

### 🛠️ Dev Tools Installer

Most platforms ship CLI tools, and installing them is one of the highest-leverage things you can do for AI-assisted development. An `aws` or `vercel` CLI gives your agent direct access to manage infrastructure, deployments, and services — no web dashboard required. The optional installer gets them all set up in one pass. Works on macOS and Linux/WSL. Safe to re-run.

**macOS / Linux / WSL:**

```bash
curl -fsSL https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit/extras/dev-tools/install.sh | bash
```

**Windows:** Run the bootstrap script first to set up WSL + Ubuntu, then the dev-tools installer runs automatically inside it:

```powershell
# PowerShell (as Administrator)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit/extras/dev-tools/bootstrap-windows.ps1" -OutFile "$env:TEMP\bootstrap-windows.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\bootstrap-windows.ps1"
```

## 🧭 Philosophy

**Opinionated but not intrusive.** Strong opinions about structure, zero lock-in. It's just files — delete them and move on.

**Conventions over configuration.** No settings files to learn. Fill in templates, the conventions do the rest.

**AI agents are team members.** Everything is written for both humans and AI. Your assistant is a first-class contributor that needs context to do good work.

**CLI over dashboard.** Every major platform ships a CLI. Installing them gives your AI agent superpowers — deploy, configure, monitor, and manage services directly from the terminal.

**Bypass mode over permission prompts.** Let the agent work. Review the output. Catch issues where they should be caught: at commit and deploy time.

**Enforce quality at the repo level.** Don't slow agents down with approval gates. Build a CI pipeline that catches problems automatically on every PR.

**Scale through structure.** A weekend project doesn't need this. But the moment your project outgrows a single prompt, structure is what keeps AI effective.

## 🎯 Who This Is For

Developers using AI coding assistants who want their projects to stay manageable as they grow — solo devs shipping fast, teams that want consistent conventions without heavy tooling, and anyone tired of their AI forgetting context between sessions.

---

<p align="center">
  <strong>Stop vibing into chaos. Start vibing with structure.</strong> ✨
  <br /><br />
  MIT License
</p>
