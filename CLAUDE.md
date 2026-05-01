# CLAUDE.md

## Project Overview

VibeStack is a Claude Code plugin that gives AI agents project structure, skills, and conventions. It installs at the **user level** (`~/.claude/`) via `curl | bash` (which also auto-installs the Claude CLI if missing and chain-installs declared plugin dependencies) or via `/plugin install vibestack@vibestackmd-vibestack` directly. Per-project scaffolding (CLAUDE.md, Makefile, docs/, TODO.md) is created on demand by the `/vibestack` slash command, not auto-installed.

The plugin's manifest (`plugin.json`) declares **dependencies** on five official Anthropic plugins: four LSP integrations (`typescript-lsp`, `pyright-lsp`, `rust-analyzer-lsp`, `gopls-lsp`) and `frontend-design`. Cross-marketplace dependencies are allowed via `allowCrossMarketplaceDependenciesOn` in `marketplace.json`. Installing VibeStack chain-installs all five automatically.

## Tech Stack

- **Site:** Next.js (in `site/`)
- **Plugin/Kit:** Plain Markdown skills, bash hooks, JSON config (in `kit/`)
- **Installer:** Bash (`install.sh`) — detects/installs Claude CLI, drops kit files, deep-merges `~/.claude/settings.json`, runs `claude plugin install vibestack@vibestackmd-vibestack` to chain-install dependencies
- **Plugin manifest:** Built by `scripts/build-plugin.sh` — generates `plugin.json` with `dependencies` array, rewrites `$HOME` and `$CLAUDE_PROJECT_DIR` hook paths to `${CLAUDE_PLUGIN_ROOT}` for plugin-distribution mode
- **Tests:** E2E bash tests, run in Docker for cross-platform coverage. Note: tests run without `claude` on $PATH, so the plugin install branch is silently skipped — real validation requires running curl|bash on a real machine
- **CI/CD:** GitHub Actions — releases triggered by version tags

## Commands

All operations go through the `Makefile`:

```bash
make help            # Show all commands
make dev             # Run site dev server
make build           # Build site
make deploy          # Build and deploy site to Vercel
make plugin          # Build Claude Code plugin to dist/
make release-patch   # Bump patch version, tag, and push
make release-minor   # Bump minor version, tag, and push
make release-major   # Bump major version, tag, and push
make test            # Quick E2E tests
make test-ubuntu     # Full Ubuntu install test (Docker)
make test-wsl        # WSL simulation test (Docker)
make clean           # Remove build artifacts
```

## Project Structure

```
install.sh              # Main installer (curl | bash entry point) — installs to ~/.claude/
kit/                    # Files shipped to ~/.claude/ at install time
  .claude/skills/       # Skills (vibestack, todo, squad, docs, bosskey, ideate, cli-first, developer-environment, lsp)
    vibestack/templates/  # Template files (CLAUDE.md, Makefile) emitted by /vibestack
  .claude/hooks/        # Hooks (notify-done, statusline)
  .claude/settings.json # Default user-level settings template (deep-merged on install)
  docs/                 # Documentation templates
  extras/               # Optional add-ons (dev-tools installer, ci-guards)
site/                   # Website (Next.js, deployed to vibestack.md)
tests/e2e/              # End-to-end install tests
scripts/                # Build scripts
VERSION                 # Single source of truth for plugin version
Makefile                # All developer commands
```

## Releasing

`VERSION` is the single source of truth. Never edit it manually or create tags by hand. Use:

```bash
make release-patch   # 0.1.6 → 0.1.7
make release-minor   # 0.1.7 → 0.2.0
make release-major   # 0.2.0 → 1.0.0
```

The release target runs preflight checks (clean tree, on main, in sync with origin, tag doesn't exist), runs E2E tests, bumps VERSION, commits, tags, and pushes. CI rejects tags that don't match the VERSION file.

## How to Do a Release

When the user asks for a release, follow this sequence exactly:

1. **Commit first.** `make release-*` requires a clean working tree. If there are uncommitted changes, commit them before attempting the release. Stage specific files — don't use `git add -A`.

2. **Sync with origin.** The preflight checks require `HEAD == origin/main`. Before running the release:
   ```bash
   git pull --rebase origin main
   git push origin main
   ```
   Use `--rebase` to avoid merge commits. Push after rebasing so the local and remote SHAs match.

3. **Run the release.** Pipe `y` to auto-confirm:
   ```bash
   echo "y" | make release-patch   # or release-minor / release-major
   ```
   This runs E2E tests, bumps VERSION, commits, tags, and pushes. Use a longer timeout (~5 min) since Docker tests run during this step.

4. **Confirm success.** Look for the "Pushed vX.Y.Z" message at the end. GitHub Actions handles the rest.

Common pitfalls:
- **Divergent branches:** Always use `git pull --rebase`, never a plain `git pull` (no pull strategy is configured globally).
- **Out of sync after rebase:** Rebasing changes the commit hash, so you must `git push` before `make release-*` will pass the sync check.
- **Don't create tags manually.** The Makefile handles tagging. Manual tags will desync from VERSION.

## Conventions

- Keep the installer idempotent and safe to re-run
- Skills are plain Markdown (`SKILL.md`) — no build step
- Installs are user-level (`~/.claude/`). Don't add per-project file drops back to `install.sh`; new project-scaffolding goes in the `/vibestack` skill instead.
- Templates emitted by `/vibestack` live at `kit/.claude/skills/vibestack/templates/` — they are NOT this repo's own CLAUDE.md/Makefile.
- **Settings.json merge is additive except for two clobber paths:** `skipDangerousModePermissionPrompt` and `permissions.defaultMode`. These are the framework's load-bearing opinions and overwrite existing user values. Don't add to the clobber list without strong justification.
- **The plugin's `dependencies` field is the canonical place to declare which other plugins VibeStack assumes.** Don't add per-plugin install loops to `install.sh` — the dependencies array does it for free via chain-install.
- The README is the single source of truth for the website
