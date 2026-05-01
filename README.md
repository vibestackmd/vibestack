<p align="center">
  <h1 align="center"><img src="site/public/favicon.svg" width="36" height="36" alt="VibeStack logo" style="vertical-align: middle;"> VibeStack</h1>
  <p align="center">
    <strong>Give your AI agents the context to build, not guess.</strong>
    <br />
    Opinionated skills, hooks, and conventions for AI-assisted development.
  </p>
  <p align="center">
    <a href="https://github.com/vibestackmd/vibestack">GitHub</a> · <a href="https://vibestack.md">Website</a>
  </p>
</p>

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/install.sh | bash
```

Run from anywhere — VibeStack installs at the **user level** (`~/.claude/`), so its skills and hooks apply across every project on your machine. Existing values in `~/.claude/settings.json` are preserved (deep-merged, never clobbered).

Then run `/vibestack` inside any project to scaffold it.

<details>
<summary>Or install as a Claude Code plugin</summary>

<br />

```
/plugin install vibestackmd/vibestack
```

Lands at user level the same way as `curl | bash`.

</details>

---

## What You Get

**Installed once at the user level:**

<table>
  <tr>
    <td><code>~/.claude/skills/</code></td>
    <td style="padding: 8px 16px;">Reference skills that auto-load as context, plus slash commands for project workflows</td>
  </tr>
  <tr>
    <td><code>~/.claude/hooks/</code></td>
    <td style="padding: 8px 16px;">Status line and finish-chime — work in every directory, including non-repos</td>
  </tr>
  <tr>
    <td><code>~/.claude/settings.json</code></td>
    <td style="padding: 8px 16px;">Opinionated defaults: skip-dangerous-mode prompt, voice on, official LSP plugins enabled</td>
  </tr>
</table>

**Created on demand by `/vibestack`** (per project, only when you ask):

<table>
  <tr>
    <td><code>CLAUDE.md</code></td>
    <td style="padding: 8px 16px;">Quick-start reference card — tells any contributor (human or AI) what this project is, how it's built, how to work in it</td>
  </tr>
  <tr>
    <td><code>TODO.md</code></td>
    <td style="padding: 8px 16px;">Lightweight task tracker with a protocol for parallel work so agents don't collide</td>
  </tr>
  <tr>
    <td><code>Makefile</code></td>
    <td style="padding: 8px 16px;">Project operations via <code>make</code> — <code>make build</code>, <code>make test</code>, <code>make deploy TARGET=prod</code>. Complex scripts go in <code>scripts/</code></td>
  </tr>
  <tr>
    <td><code>docs/</code></td>
    <td style="padding: 8px 16px;">Living knowledge base — the docs you write today prevent your AI from re-discovering the same lessons tomorrow</td>
  </tr>
</table>

`/vibestack` skips any artifact that already exists. Safe to re-run.

## Slash Commands

<table>
  <tr>
    <td><code>/vibestack</code></td>
    <td style="padding: 8px 16px;">Analyzes your project and creates CLAUDE.md, Makefile, docs, and TODO.md with project-specific content</td>
  </tr>
  <tr>
    <td><code>/squad</code></td>
    <td style="padding: 8px 16px;">Generates domain-specific rules and specialist subagents so Claude auto-loads the right context per file. Always preserves manual edits — safe to re-run</td>
  </tr>
  <tr>
    <td><code>/todo</code></td>
    <td style="padding: 8px 16px;">Works through TODO.md tasks. <code>/todo 3</code> runs only task #3. <code>/todo refresh</code> rewrites the list ranked by impact</td>
  </tr>
  <tr>
    <td><code>/docs</code></td>
    <td style="padding: 8px 16px;">Captures conversation learnings into your docs folder and cleans up stale content</td>
  </tr>
  <tr>
    <td><code>/ideate</code></td>
    <td style="padding: 8px 16px;">Strategy session with a co-founder persona — critical, constructive, invested. Read-only; for thinking through ideas before building</td>
  </tr>
  <tr>
    <td><code>/bosskey</code></td>
    <td style="padding: 8px 16px;">Scans your recent git history and generates a polished standup script you can recite to your boss — vague enough to avoid follow-ups, impressive enough to sound productive</td>
  </tr>
</table>

<br />

Plus reference skills that auto-load as context (no command needed):

- `cli-first` — teaches your AI to use platform CLIs and check `.env*` files instead of making raw API calls
- `developer-environment` — a self-populating map of what's installed on your machine (languages, runtimes, DBs, cloud CLIs) so Claude stops guessing whether tools are available

LSP coverage is handled via official Claude Code plugins (`rust-analyzer-lsp`, etc.), not a skill.

---

## Extras

### CI Guards

Reusable GitHub Actions workflows: lint, test coverage, security scans, code smell checks on every PR. Supports Node/TypeScript, Python, Rust, and Go.

```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/install.sh | bash -s -- <language>
```

### Dev Tools Installer

One-pass installer for platform CLIs (aws, vercel, etc.) — giving your AI agent direct infrastructure access from the terminal.

**macOS / Linux / WSL:**

```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/dev-tools/install.sh | bash
```

**Windows:** Run the bootstrap script first to set up WSL + Ubuntu:

```powershell
# PowerShell (as Administrator)
Invoke-RestMethod "https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/dev-tools/bootstrap-windows.ps1" | Set-Content "$env:TEMP\bootstrap-windows.ps1"; powershell -ExecutionPolicy Bypass -File "$env:TEMP\bootstrap-windows.ps1"
```

### The `claw` Alias

The dev-tools installer offers to add `claw` to your shell — an alias for `claude --permission-mode bypassPermissions --`. Use it anywhere to run Claude uninterrupted.

```bash
claw "refactor the auth module to use JWT"
```

---

## Opinions

This is what makes VibeStack different. The conventions above give your work structure — the opinions below are why.

### User-level, Not Per-project

Your dev environment is the same regardless of which repo you're in. Skills, hooks, and Claude defaults belong at user level, not duplicated into every `.claude/` folder you own. VibeStack installs once and applies everywhere — no more "I forgot to update VibeStack in this project."

### Makefile Over Shell Scripts

Your project operations belong in a `Makefile`, not a bespoke shell script. `make` is universal, tab-completable, dependency-aware, and self-documenting. Keep targets thin — if something needs real bash logic, put it in `scripts/` and call it from the target. One command to rule them all: `make help`.

### Bypass Permissions

VibeStack ships with `skipDangerousModePermissionPrompt: true` and all tool permissions pre-approved. No "can I run this command?" prompts. Permission prompts kill flow and add no real safety. Code quality enforcement belongs in your CI pipeline and pre-commit hooks, not in an interactive approval flow.

### Squad Mode

Large codebases overwhelm AI context windows. `/squad` analyzes your project and breaks it into logical domains — each getting its own path-specific rules (`.claude/rules/`) and optionally a specialist subagent (`.claude/agents/`). When Claude touches a file in the auth domain, it automatically loads auth-specific conventions. Re-run `/squad` whenever your project grows; manual edits are always preserved.

### CI Over Approval Gates

AI agents write bad code sometimes. The answer isn't slowing your agent down — it's a CI pipeline that catches problems automatically. Bypass mode + CI Guards = maximum speed with maximum accountability.

### Finish Notification

When Claude finishes a task, your machine plays a chime. Kick off a task, walk away, get an audio alert when it's done.

---

<p align="center">
  <strong>Stop vibing into chaos. Start vibing with structure.</strong> ✨
  <br /><br />
  MIT License
</p>
