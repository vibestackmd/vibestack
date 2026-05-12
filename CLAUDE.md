# CLAUDE.md

## Project Overview

VibeStack is a Claude Code plugin that gives AI agents project structure, skills, and conventions. It installs at the **user level** (`~/.claude/`) via `curl | bash` (which also auto-installs the Claude CLI if missing and chain-installs declared plugin dependencies) or via `/plugin install vibestack@vibestackmd-vibestack` directly. Per-project scaffolding (CLAUDE.md, Makefile, docs/, TODO.md) is created on demand by the `/vibestack` slash command, not auto-installed.

The plugin's manifest (`plugin.json`) declares **dependencies** on five official Anthropic plugins: four LSP integrations (`typescript-lsp`, `pyright-lsp`, `rust-analyzer-lsp`, `gopls-lsp`) and `frontend-design`. Cross-marketplace dependencies are allowed via `allowCrossMarketplaceDependenciesOn` in `marketplace.json`. Installing VibeStack chain-installs all five automatically.

## Tech Stack

- **Site:** Next.js (in `site/`)
- **Plugin:** The repo root **is** the plugin root. `.claude-plugin/{plugin,marketplace}.json`, `skills/`, `hooks/`, and the plugin's `settings.json` all live at root. `claude plugin marketplace add vibestackmd/vibestack` clones the repo and finds everything in place.
- **Installer:** Bash (`install.sh`) — detects/installs Claude CLI, deep-merges `user.settings.json` into `~/.claude/settings.json` (user-level keys only — voiceEnabled, enabledPlugins, defaultMode, etc), then `claude plugin marketplace add anthropics/claude-plugins-official` + `vibestackmd/vibestack` and `claude plugin install vibestack@vibestackmd-vibestack`
- **Build:** `scripts/build-plugin.sh` syncs VERSION → `.claude-plugin/{plugin,marketplace}.json`, validates the plugin tree, and emits two artifacts: `dist/vibestack-plugin-X.Y.Z.tar.gz` (release asset) and `dist/test-marketplace/` (used by `make test-local-marketplace`).
- **Tests:** E2E bash tests, run in Docker. Three suites: `preinstalled` (settings merge), `ubuntu` (full installer + dev-tools), `local-marketplace` (real Claude CLI installs the about-to-ship plugin from a local marketplace).
- **CI/CD:** GitHub Actions — releases triggered by version tags. The `release-plugin.yml` workflow only builds the tarball + publishes the GitHub Release; manifests are committed in-tree so there's no post-release rewrite step.

## Commands

All operations go through the `Makefile`:

```bash
make help            # Show all commands
make dev             # Run site dev server
make build           # Build site
make deploy          # Build and deploy site to Vercel
make plugin                    # Sync manifests, validate, build tarball + test marketplace
make release-patch             # Bump patch version, tag, and push
make release-minor             # Bump minor version, tag, and push
make release-major             # Bump major version, tag, and push
make test                      # Quick E2E tests (preinstalled suite)
make test-ubuntu               # Full Ubuntu install test (Docker)
make test-wsl                  # WSL simulation test (Docker)
make test-local-marketplace    # Real Claude CLI + locally-built plugin (E2E)
make clean                     # Remove build artifacts
```

## Project Structure

```
install.sh                # curl | bash entry point — drops user.settings.json + chain-installs the plugin
.claude-plugin/
  plugin.json             # Plugin manifest (name, version, deps). Committed; version synced by build script.
  marketplace.json        # Marketplace manifest (owner, plugins[], cross-mkt allowlist). Committed.
skills/                   # Plugin-shipped skills (vibestack, todo, squad, docs, bosskey, ideate, cli-first, developer-environment, lsp)
  vibestack/templates/    # CLAUDE.md + Makefile emitted by the /vibestack skill
hooks/                    # Plugin hooks (notify-done, statusline) + hooks.json registering them; paths use ${CLAUDE_PLUGIN_ROOT}
hooks/hooks.json          # Plugin hook registrations (Stop → notify-done). Loaded by Claude when the plugin is enabled.
settings.json             # Plugin's settings.json — statusLine only. (Hooks go in hooks/hooks.json, NOT here.)
user.settings.json        # User-level settings template (voiceEnabled, enabledPlugins, defaultMode, etc) — fetched by install.sh and deep-merged into ~/.claude/settings.json
extras/                   # Optional add-ons (dev-tools installer, ci-guards) — separate from the plugin
site/                     # Website (Next.js, deployed to vibestack.md)
tests/e2e/                # End-to-end install tests (Docker)
scripts/build-plugin.sh   # Syncs VERSION into manifests, validates, builds tarball + test-marketplace
VERSION                   # Single source of truth for plugin version
Makefile                  # All developer commands
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
- Templates emitted by `/vibestack` live at `skills/vibestack/templates/` — they are NOT this repo's own CLAUDE.md/Makefile.
- **`user.settings.json` carries user-level keys ONLY** (no statusLine, no hooks). Plugin-level `statusLine` lives in the plugin's own `settings.json` at repo root; plugin hooks live in `hooks/hooks.json` (NOT in `settings.json` — Claude's plugin loader reads hooks from `hooks/hooks.json` only, matching every official Anthropic plugin). Both reference `${CLAUDE_PLUGIN_ROOT}` for script paths.
- **Settings merge is additive except for two clobber paths:** `skipDangerousModePermissionPrompt` and `permissions.defaultMode`. These are the framework's load-bearing opinions and overwrite existing user values. Don't add to the clobber list without strong justification.
- **The plugin's `dependencies` field is the canonical place to declare which other plugins VibeStack assumes.** Don't add per-plugin install loops to `install.sh` — the dependencies array does it for free via chain-install. `install.sh` does explicitly add `anthropics/claude-plugins-official` first because fresh Claude installs have no marketplaces configured.
- **Manifests (`plugin.json`, `marketplace.json`) are committed in-tree.** `make plugin` syncs the version field from VERSION before each release. CI does not rewrite them post-release.
- The README is the single source of truth for the website
