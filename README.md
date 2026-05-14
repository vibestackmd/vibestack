<p align="center">
  <h1 align="center"><img src="site/public/favicon.svg" width="36" height="36" alt="VibeStack logo" style="vertical-align: middle;"> VibeStack</h1>
  <p align="center">
    <strong>The best practices I'd give a new teammate, taught to Claude.</strong>
  </p>
  <p align="center">
    <a href="https://github.com/vibestackmd/vibestack">GitHub</a> · <a href="https://vibestack.md">Website</a> · <a href="LICENSE">MIT</a>
  </p>
</p>

---

Every developer builds up a set of conventions over time. How you structure a project, where logic lives, what "done" actually means, which corners are safe to cut and which will burn you later. Mine took years to settle. They lived in my head, and I re-explained them to every new Claude session and every new person on my team.

VibeStack is where I keep them now. It's an opinionated Claude Code setup, skills and hooks and sane defaults, that teaches Claude to work the way I do. Install it once and every project on your machine inherits it. Hand it to someone you work with and they're building with the same conventions on day one, without you having to look over their shoulder.

It's opinionated on purpose. The value is that the calls are already made.

## The Opinions

This is the part that matters. The skills and commands further down are just the delivery mechanism. These are the actual decisions.

**User-level, not per-project.** Your conventions don't change between repos, so they shouldn't be copied into every `.claude/` folder you own. VibeStack installs once at `~/.claude/` and applies everywhere. There's no "I forgot to update it in this project."

**Bypass permissions, always.** Every session starts in bypass mode with the startup warning suppressed. Permission prompts break flow and don't add real safety. A prompt you click through on autopilot was never a safety check. Code quality belongs in CI and pre-commit hooks, not an approval dialog.

**CI over approval gates.** Agents write bad code sometimes. The fix isn't slowing the agent down, it's a pipeline that catches problems automatically. Run `/cicd` and you have one. Bypass mode plus real CI is fast and accountable at the same time.

**Makefile over shell scripts.** Every project's operations go behind `make`: `make build`, `make test`, `make deploy`. It's universal, tab-completable, and self-documenting. Anything that needs real bash logic goes in `scripts/` and gets called from a target.

**Write like a person.** The `prose` skill bans em dashes and the other tells that make text obviously AI-generated. Small thing, but it's the kind of detail that separates output you'd ship from output you'd be embarrassed by.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/install.sh | bash
```

Run it from anywhere. Then run `/vibestack` inside any project to scaffold it.

<details>
<summary>What the installer actually does</summary>

<br />

1. **Detects the Claude CLI** and offers to install it if it's missing, so you can hand the command to someone who's never used Claude and they still end up set up.
2. **Deep-merges `~/.claude/settings.json`.** Your existing values are preserved. Only two keys are overwritten (`permissions.defaultMode` and `skipDangerousModePermissionPrompt`), because the no-prompts experience is the whole point.
3. **Installs the plugin**, which chain-installs its dependencies: the four official LSP plugins (TypeScript, Python, Rust, Go) and Anthropic's `frontend-design`.

</details>

<details>
<summary>Install via Claude plugin only (no curl)</summary>

<br />

```
/plugin marketplace add vibestackmd/vibestack
/plugin install vibestack@vibestackmd-vibestack
```

You get the same skills, hooks, and chain-installed plugins. You miss the user-level settings (bypass mode, the statusline), because those need write access to `~/.claude/settings.json` that only the `curl | bash` path has. That's the tradeoff: plugin-only is less opinionated, by design.

</details>

## What's Inside

**Slash commands**, run when you want them:

| Command | What it does |
|---|---|
| `/vibestack` | Scaffolds a project. Reads the codebase, then writes a CLAUDE.md, Makefile, `docs/`, and TODO.md with real content. Skips anything that already exists, so it's safe to re-run. |
| `/cicd` | Detects your language stack and writes a self-contained `.github/workflows/ci.yml` with lint, test, and build gates. Node, Python, Go, Rust. |
| `/squad` | Breaks a large codebase into domains, each with its own path-specific rules and an optional specialist subagent, so Claude loads the right context per file. |
| `/todo` | Works through TODO.md one task at a time. `/todo 3` runs task #3; `/todo refresh` re-ranks the list by impact. |
| `/docs` | Captures what you learned this session into `docs/` and clears out anything stale. |
| `/ideate` | A strategy session with a co-founder persona: critical, invested, read-only. For thinking an idea through before you build it. |
| `/bosskey` | Turns your recent git history into a standup script that sounds good without inviting follow-up questions. |

**Reference skills** that auto-load as context, no command needed:

- `cli-first`, use platform CLIs and `.env` files instead of raw API calls
- `developer-environment`, a self-updating map of what's installed on your machine so Claude stops guessing
- `lsp`, use language servers for type-checking and find-references; pairs with the official `*-lsp` plugins
- `prose`, the writing rules from above

**Hooks and defaults**, installed at the user level:

- A statusline showing your current directory, model, and context usage, in every directory including non-repos
- A finish chime, so you can start a long task, walk away, and get called back when it's done
- The opinionated `settings.json` defaults: bypass mode, no startup warning, LSP plugins enabled

## Extras

Optional, and not part of the core plugin.

**Dev-tools installer.** One pass to install the platform CLIs (AWS, Vercel, Supabase, Stripe, GitHub, and the rest) so Claude can manage infrastructure from the terminal instead of guessing.

```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/extras/dev-tools/install.sh | bash
```

On Windows, run `extras/dev-tools/bootstrap-windows.ps1` from an Administrator PowerShell first. It sets up WSL and Ubuntu, then runs the installer inside it.

**The `claw` alias.** The dev-tools installer offers to add `claw`, shorthand for `claude --permission-mode bypassPermissions --`. Run Claude uninterrupted from anywhere:

```bash
claw "refactor the auth module to use JWT"
```

---

<p align="center">
  MIT License
</p>
