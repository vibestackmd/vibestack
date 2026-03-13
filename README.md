<p align="center">
  <h1 align="center"><img src="site/public/favicon.svg" width="36" height="36" alt="VibeStack logo" style="vertical-align: middle;"> VibeStack</h1>
  <p align="center">
    <strong>Give your AI agents the context to build not guess.</strong>
    <br />
    Opinionated project structure, skills, and tooling for AI-assisted development.
  </p>
  <p align="center">
    <a href="https://github.com/vibestackmd/vibestack">GitHub</a> · <a href="https://vibestack.md">Website</a>
  </p>
</p>

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/install.sh | bash
```

Run from the root of your project. Existing files are never overwritten.

Then run `/vibestack` inside Claude Code to auto-fill everything for your project.

<details>
<summary>Or install as a Claude Code plugin</summary>

<br />

If you just want the skills and hooks without project templates:

```
/plugin install vibestackmd/vibestack
```

Then run `/vibestack` inside any project to scaffold CLAUDE.md, ops.sh, docs, and TODO.md.

</details>

---

## What You Get

Five files:

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
    <td><code>ops.sh</code></td>
    <td style="padding: 8px 16px;">Single entry point for build, test, run, deploy — <code>./ops.sh build</code>, <code>./ops.sh test</code>, <code>./ops.sh deploy prod</code></td>
  </tr>
  <tr>
    <td><code>docs/</code></td>
    <td style="padding: 8px 16px;">Living knowledge base — the docs you write today prevent your AI from re-discovering the same lessons tomorrow</td>
  </tr>
  <tr>
    <td><code>.claude/skills/</code></td>
    <td style="padding: 8px 16px;">Teach AI your project's conventions and workflows via reusable skills</td>
  </tr>
</table>

## Skills

<table>
  <tr>
    <td><code>/vibestack</code></td>
    <td style="padding: 8px 16px;">Analyzes your project and fills out CLAUDE.md, ops.sh, docs, and TODO.md with project-specific content</td>
  </tr>
  <tr>
    <td><code>/squad</code></td>
    <td style="padding: 8px 16px;">Generates domain-specific rules and specialist subagents so Claude auto-loads the right context per file</td>
  </tr>
  <tr>
    <td><code>/todo</code></td>
    <td style="padding: 8px 16px;">Works through TODO.md tasks sequentially. <code>/todo populate</code> seeds the next batch ranked by impact</td>
  </tr>
  <tr>
    <td><code>/docs</code></td>
    <td style="padding: 8px 16px;">Captures conversation learnings into your docs folder and cleans up stale content</td>
  </tr>
</table>

<br />

Also includes reference skills that auto-load as context:

- `cli-first` — teaches your AI to use platform CLIs and check `.env*` files instead of making raw API calls
- `lsp` — teaches your AI to use language servers for type checking, go-to-definition, find-references, and post-change validation

---

## Extras

### CI Guards

Reusable GitHub Actions workflows: lint, test coverage, security scans, code smell checks on every PR. Supports Node/TypeScript, Python, Rust, and Go.

```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/install.sh | bash -s -- <language>
```

### Dev Tools Installer

One-pass installer for platform CLIs (aws, vercel, etc.) and language servers (typescript-language-server, pyright, rust-analyzer, gopls) — giving your AI agent direct infrastructure access and code intelligence from the terminal.

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

<p align="center">
  <strong>Stop vibing into chaos. Start vibing with structure.</strong> ✨
  <br /><br />
  MIT License
</p>
