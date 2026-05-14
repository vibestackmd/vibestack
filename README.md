<p align="center">
  <h1 align="center"><img src="site/public/favicon.svg" width="36" height="36" alt="VibeStack logo" style="vertical-align: middle;"> VibeStack</h1>
  <p align="center">
    <strong>Senior Developer's Conventions as a Plugin You Can Install.</strong>
  </p>
  <p align="center">
    <a href="https://github.com/vibestackmd/vibestack">GitHub</a> &nbsp;·&nbsp; <a href="https://vibestack.md">Website</a> &nbsp;·&nbsp; <a href="LICENSE">MIT</a>
  </p>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/vibestackmd/vibestack/main/site/public/demo.gif" alt="VibeStack install demo" width="820">
</p>

**Opinionated on purpose:** bypass permissions · CLI-first · CI/CD gates · religious markdown documentation · `make` as the entry point

---

## Install

**Full install.** The plugin plus user-level settings, hooks, and an optional dev-tools pass. The complete setup.

```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/install.sh | bash
```

**Plugin only.** Just the skills, hooks, and chain-installed dependencies. No user-level settings.

```
/plugin marketplace add vibestackmd/vibestack
/plugin install vibestack@vibestackmd-vibestack
```

> ⚡ &nbsp; **Then run `/vibestack` in any project to scaffold it.**

---

## What's Inside

**Slash commands**, run when you want them:

| Command | What it does |
|---|---|
| `/vibestack` | Scaffolds a project: CLAUDE.md, Makefile, `docs/`, TODO.md, with real content. Safe to re-run. |
| `/cicd` | Writes a self-contained `.github/workflows/ci.yml` for your stack. Node, Python, Go, Rust. |
| `/squad` | Breaks a big codebase into domains, each with its own rules and an optional specialist subagent. |
| `/todo` | Works through TODO.md one task at a time. `/todo refresh` re-ranks by impact. |
| `/docs` | Captures what you learned this session into `docs/`, clears out the stale stuff. |
| `/ideate` | A strategy session with a co-founder persona. Critical, invested, read-only. |
| `/bosskey` | Turns your git history into a standup script that sounds good without inviting questions. |

**Reference skills**, auto-loaded as context (no command needed):

- `cli-first`: use platform CLIs and `.env` files, not raw API calls
- `developer-environment`: a self-updating map of what's installed on your machine
- `lsp`: language servers for type-checking and find-references
- `prose`: write like a person, no em dashes, no AI tells

**Hooks and defaults**, at the user level:

- A statusline with your current directory, model, and context usage
- A finish chime, so you can walk away from a long task and get called back
- Bypass mode and LSP plugins, on by default

---

## Extras

Optional. Not part of the core plugin.

**Dev-tools installer.**<br>
One pass to install the platform CLIs (AWS, Vercel, Supabase, Stripe, GitHub) so Claude manages infrastructure from the terminal.

```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/extras/dev-tools/install.sh | bash
```

On Windows, run `extras/dev-tools/bootstrap-windows.ps1` from an Administrator PowerShell first.

**The `claw` alias.**<br>
Shorthand for `claude --permission-mode bypassPermissions --`. Run Claude uninterrupted from anywhere.

```bash
claw "refactor the auth module to use JWT"
```

---

<p align="center">
  MIT License
</p>
