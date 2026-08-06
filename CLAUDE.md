# CLAUDE.md

## Project Overview

VibeStack is a Claude Code plugin that gives AI agents project structure, skills, and conventions. It installs at the **user level** (`~/.claude/`) via `curl | bash` (which also auto-installs the Claude CLI if missing and chain-installs declared plugin dependencies) or via `/plugin install vibestack@vibestackmd-vibestack` directly. Per-project scaffolding (CLAUDE.md, Makefile, docs/, TODO.md) is created on demand by the `/vibestack` slash command, not auto-installed.

The plugin's manifest (`plugin.json`) declares **dependencies** on five official Anthropic plugins: four LSP integrations (`typescript-lsp`, `pyright-lsp`, `rust-analyzer-lsp`, `gopls-lsp`) and `frontend-design`. Cross-marketplace dependencies are allowed via `allowCrossMarketplaceDependenciesOn` in `marketplace.json`. Installing VibeStack chain-installs all five automatically.

## Tech Stack

- **Site:** Next.js (in `site/`)
- **Plugin:** The repo root **is** the plugin root. `.claude-plugin/{plugin,marketplace}.json`, `skills/`, and `hooks/` all live at root. `claude plugin marketplace add vibestackmd/vibestack` clones the repo and finds everything in place.
- **Installer:** Bash (`install.sh`). Detects/installs the Claude CLI, deep-merges `user.settings.json` into `~/.claude/settings.json` (user-level keys: statusLine, defaultMode, companyAnnouncements, skipDangerousModePermissionPrompt), then runs `claude plugin marketplace add anthropics/claude-plugins-official` + `vibestackmd/vibestack` and `claude plugin install vibestack@vibestackmd-vibestack` (which chain-installs and auto-enables the LSP + frontend-design deps from plugin.json).
- **Build:** `scripts/build-plugin.sh` syncs VERSION → `.claude-plugin/{plugin,marketplace}.json`, validates the plugin tree, and emits two artifacts: `dist/vibestack-plugin-X.Y.Z.tar.gz` (release asset) and `dist/test-marketplace/` (used by `make test-local-marketplace`).
- **Tests:** E2E bash tests. Run in Docker. Three suites: `preinstalled` (settings merge), `ubuntu` (full installer + dev-tools), `local-marketplace` (real Claude CLI installs the about-to-ship plugin from a local marketplace).
- **CI/CD:** GitHub Actions. Releases triggered by version tags. The `release-plugin.yml` workflow only builds the tarball + publishes the GitHub Release; manifests are committed in-tree so there's no post-release rewrite step.

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
install.sh                # curl | bash entry point, drops user.settings.json + chain-installs the plugin
.claude-plugin/
  plugin.json             # Plugin manifest (name, version, deps). Committed; version synced by build script.
  marketplace.json        # Marketplace manifest (owner, plugins[], cross-mkt allowlist). Committed.
skills/                   # Plugin-shipped skills (vibestack, todo, squad, docs, bosskey, ideate, cli-first, developer-environment, lsp, cicd, prose)
  vibestack/templates/    # CLAUDE.md + Makefile emitted by the /vibestack skill
hooks/                    # Hook scripts. notify-done.sh is plugin-scoped (registered via hooks/hooks.json); statusline.sh is fetched by install.sh to ~/.claude/hooks/ for the user-level statusLine.
hooks/hooks.json          # Plugin hook registrations (Stop → notify-done). Loaded by Claude when the plugin is enabled.
user.settings.json        # User-level settings template (statusLine, defaultMode, companyAnnouncements, skipDangerousModePermissionPrompt), fetched by install.sh and deep-merged into ~/.claude/settings.json. Plugin enablement is NOT listed here, chain-install via plugin.json `dependencies` is the single source of truth.
extras/                   # Optional add-ons (dev-tools installer), separate from the plugin
site/                     # Website (Next.js, deployed to vibestack.md). Renders README.md directly; the README is the single source of truth.
tests/e2e/                # End-to-end install tests (Docker)
tests/validate-skills.sh  # Local skill lint (frontmatter + /cicd YAML snippets). Runs inside `make plugin`, no Docker.
scripts/build-plugin.sh   # Syncs VERSION into manifests, validates, runs skill lint, builds tarball + test-marketplace
CHANGELOG.md              # Hand-written release history. Update it when cutting a release.
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

1. **Update `CHANGELOG.md`.** Add an entry for the version about to ship, describing the *why* of the change, not just the *what*. This is part of the same commit as the change itself.

2. **Commit first.** `make release-*` requires a clean working tree. If there are uncommitted changes, commit them before attempting the release. Stage specific files, don't use `git add -A`.

3. **Sync with origin.** The preflight checks require `HEAD == origin/main`. Before running the release:
   ```bash
   git pull --rebase origin main
   git push origin main
   ```
   Use `--rebase` to avoid merge commits. Push after rebasing so the local and remote SHAs match.

4. **Run the release.** Pipe `y` to auto-confirm:
   ```bash
   echo "y" | make release-patch   # or release-minor / release-major
   ```
   This runs E2E tests, bumps VERSION, commits, tags, and pushes. Use a longer timeout (~5 min) since Docker tests run during this step.

5. **Confirm success.** Look for the "Pushed vX.Y.Z" message at the end. GitHub Actions handles the rest.

Common pitfalls:
- **Divergent branches:** Always use `git pull --rebase`. Never a plain `git pull` (no pull strategy is configured globally).
- **Out of sync after rebase:** Rebasing changes the commit hash. So you must `git push` before `make release-*` will pass the sync check.
- **Don't create tags manually.** The Makefile handles tagging. Manual tags will desync from VERSION.
- **Signed tags need a message.** This repo's git config sets `tag.gpgsign=true`, which makes every tag annotated, and an annotated tag with no message opens an editor. Under `echo y |` there is no TTY, so the tag step aborts with `fatal: no tag message?`. The Makefile passes `-m` for this reason; do not remove it.
- **GitHub can be slow to fire the tag workflow.** After a successful push, `Release Plugin` has taken several minutes to appear in `gh run list`. Wait before concluding it failed.

### Recovering a half-cut release

If `make release-*` fails *after* the release commit but *before* the push, the
tree has a `release vX.Y.Z` commit with `VERSION` and both manifests already
bumped, but no tag and nothing pushed. Do not re-run `make release-*`, its
preflight will reject the dirty state or the existing version. Finish the two
steps it did not reach:

```bash
git tag -m "release vX.Y.Z" vX.Y.Z
git push origin main vX.Y.Z
```

**Never delete a tag that already has a published GitHub Release.** Deleting the
tag demotes the release to a **draft**, so `gh release list` shows the previous
version as Latest even though the new tag exists. If that happens:

```bash
gh release edit vX.Y.Z --draft=false
```

## Verifying install/uninstall changes

When a change touches install behavior, `install.sh`, the plugin manifest, hooks, settings templates, or anything that lands under `~/.claude/`, verify it via the full uninstall → reinstall cycle against the **released** artifact, not a local checkout. Both install paths fetch from GitHub (`install.sh` pulls raw files from `main`; `claude plugin install` resolves from the published marketplace), so testing must happen after a release. `make test-local-marketplace` covers part of this in Docker but not the curl path.

The cycle is principle-based, read the *current* `install.sh` and `plugin.json` each time to figure out what to uninstall. Don't follow a frozen checklist:

1. **Ship a release first.** Push to main, then `echo y | make release-patch`. Wait for the GitHub Actions release workflow to finish (`gh run watch` or poll `gh run list`).

2. **Tear down everything the install paths could have added**, in this order:
   - Read `install.sh` and reverse every side effect it produces *outside* the plugin (files dropped under `~/.claude/`, keys merged into `~/.claude/settings.json` from `user.settings.json`, marketplaces registered).
   - Read `plugin.json` and reverse what `claude plugin install` adds: `claude plugin uninstall vibestack@vibestackmd-vibestack` then `claude plugin prune -y` for the chain-installed dependencies.
   - Remove marketplaces (`claude plugin marketplace remove`).
   - Reset `~/.claude/settings.json` to only the keys the user actually owns (back up first).

3. **Verify the clean baseline.** `claude plugin list` and `claude plugin marketplace list` should both show none of ours; no VibeStack-dropped files under `~/.claude/`; `~/.claude/settings.json` should contain only user-owned keys.

4. **Reinstall via install.sh** (the higher-coverage path):
   ```
   SKIP_DEVTOOLS=1 NONINTERACTIVE=1 curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/install.sh | bash
   ```

5. **Verify autonomously.** Cross-reference against the current `install.sh` and `plugin.json`: every side effect the install path *should* produce is present (plugin version matches release, expected skills/hooks counts via `claude plugin details`, all settings keys merged, all dropped files in place and executable). Smoke-test any hook scripts by piping representative input.

6. **Optionally test the plugin-only path** when the change could affect users who skip `install.sh`:
   ```
   claude plugin marketplace add anthropics/claude-plugins-official
   claude plugin marketplace add vibestackmd/vibestack
   claude plugin install vibestack@vibestackmd-vibestack --scope user
   ```
   Plugin-scoped features (skills, plugin hooks) must work. User-scoped features (statusLine, user-level settings keys) intentionally don't, confirm that's still the deliberate gap.

7. **Hand off for manual UI verification.** After autonomous checks pass, tell the user to restart Claude Code and visually confirm anything you can't programmatically check (statusline rendering, sound playback, etc.).

## Conventions

- Keep the installer idempotent and safe to re-run
- Skills are plain Markdown (`SKILL.md`), no build step
- Installs are user-level (`~/.claude/`). Don't add per-project file drops back to `install.sh`; new project-scaffolding goes in the `/vibestack` skill instead.
- Templates emitted by `/vibestack` live at `skills/vibestack/templates/`, they are NOT this repo's own CLAUDE.md/Makefile.
- **The "initial-setup" skill family is chained via `/vibestack`.** `/vibestack` is the entry point that scaffolds CLAUDE.md/Makefile/docs/TODO.md, then advertises sibling skills like `/cicd`, `/docs`, and `/todo`. Every initial-setup skill must be idempotent (safe to re-run) and self-contained (no external repo dependencies, no per-project bash installers, that pattern is deprecated). When you add a new skill in this family, update the "Point to sibling initial-setup skills" section in `skills/vibestack/SKILL.md` so it's discoverable as part of the chain.
- **Style-rule skills auto-load on every conversation.** `cli-first` and `prose` use `user-invocable: false` so their descriptions are always in Claude's context. They are not invoked via slash command; they shape behavior continuously. `prose` is the load-bearing one: it strictly forbids em dashes (`, `) and en dashes (`–`) as punctuation in any generated output, because em dashes are the single most reliable AI-text fingerprint. The repo itself must remain em-dash-free. When you write or paste content into any file under this repo, run a final scan for `, ` and `–` and replace with comma, period, colon, or sentence restructure before committing.
- **`user.settings.json` carries user-level keys** (defaultMode, companyAnnouncements, skipDangerousModePermissionPrompt, and the main `statusLine`). It does NOT list `enabledPlugins`, chain-install from `plugin.json` `dependencies` auto-enables the LSP + frontend-design plugins, so duplicating them here would be dead weight. The main statusLine lives here because Claude only allows plugins to contribute `subagentStatusLine` at plugin scope, not the main `statusLine`. Its `command` points to `~/.claude/hooks/statusline.sh`, which install.sh fetches from the repo and drops at user level (the only architectural exception to "no install.sh file drops", necessary because plugin-scoped `${CLAUDE_PLUGIN_ROOT}` isn't available in user-level settings). Plugin hooks (the Stop notification, etc.) live in `hooks/hooks.json` and reference `${CLAUDE_PLUGIN_ROOT}`, Claude's plugin loader reads hooks from `hooks/hooks.json` only, matching every official Anthropic plugin. The plugin does not ship its own `settings.json` (none of the plugin-scope settings keys are in use); add one back at repo root when shipping `subagentStatusLine` or another plugin-scoped key.
- **Settings merge is additive except for two clobber paths:** `skipDangerousModePermissionPrompt` and `permissions.defaultMode`. These are the framework's load-bearing opinions and overwrite existing user values. Don't add to the clobber list without strong justification.
- **The plugin's `dependencies` field is the canonical place to declare which other plugins VibeStack assumes.** Don't add per-plugin install loops to `install.sh`, the dependencies array does it for free via chain-install. `install.sh` does explicitly add `anthropics/claude-plugins-official` first because fresh Claude installs have no marketplaces configured.
- **Manifests (`plugin.json`, `marketplace.json`) are committed in-tree.** `make plugin` syncs the version field from VERSION before each release. CI does not rewrite them post-release.
- The README is the single source of truth for the website
