# Contributing

## Setup

```bash
git clone git@github.com:vibestackmd/vibestack.git
cd vibestack
cd site && npm install
```

## Commands

```
make help
```

| Command | What it does |
|---------|-------------|
| `make dev` | Run the site locally |
| `make build` | Build the site |
| `make deploy` | Build and deploy site to Vercel |
| `make plugin` | Build the Claude Code plugin to `dist/` |
| `make release-patch` | Bump patch version, tag, and push |
| `make release-minor` | Bump minor version, tag, and push |
| `make release-major` | Bump major version, tag, and push |
| `make test` | Run quick E2E tests |
| `make test-ubuntu` | Full Ubuntu install test (Docker) |
| `make test-wsl` | WSL simulation test (Docker) |
| `make clean` | Remove build artifacts |

## How VibeStack installs (v2 architecture)

Two install paths, same end state:

- **`curl | bash`** runs `install.sh`. It detects/auto-installs the Claude CLI, deep-merges `~/.claude/settings.json`, then runs `claude plugin install vibestack@vibestackmd-vibestack`. The plugin install brings the skills, hooks, and templates.
- **`/plugin install vibestack`** (or its CLI form) runs the plugin install directly. Skips the settings merge and Claude CLI install — that's the trade-off.

The plugin's `plugin.json` declares **dependencies** on five official Anthropic plugins, which Claude chain-installs automatically:

- `typescript-lsp`, `pyright-lsp`, `rust-analyzer-lsp`, `gopls-lsp` (LSP integrations)
- `frontend-design` (Anthropic's design plugin)

`marketplace.json` allows cross-marketplace deps via `allowCrossMarketplaceDependenciesOn: ["claude-plugins-official"]`.

## Project Structure

```
install.sh              # curl|bash entry point — Claude CLI + settings + plugin install
kit/                    # Source for the plugin's contents
  .claude/skills/       # Skills (vibestack, todo, squad, docs, bosskey, ideate,
                        #         cli-first, developer-environment, lsp)
    vibestack/templates/  # CLAUDE.md and Makefile templates emitted by /vibestack
  .claude/hooks/        # Hooks (notify-done, statusline)
  .claude/settings.json # User-level settings template (deep-merged on install)
  docs/                 # Documentation templates
  extras/               # Optional add-ons (dev-tools installer)
scripts/build-plugin.sh # Builds the Claude plugin tarball from kit/, writes
                        # plugin.json with dependencies, rewrites $HOME hook
                        # paths to ${CLAUDE_PLUGIN_ROOT}
marketplace.json        # Marketplace manifest — declares cross-marketplace dep allowance
site/                   # Website (Next.js, deployed to vibestack.md)
tests/e2e/              # End-to-end install tests
VERSION                 # Plugin version (semver, no v prefix)
Makefile                # Developer commands
```

## Making Changes

**Skills and hooks** live in `kit/.claude/`. Edit them there — they're packaged into the plugin by `make plugin` and shipped via `/plugin install`.

**Settings template** lives at `kit/.claude/settings.json`. Two keys are clobbered on install (`skipDangerousModePermissionPrompt` and `permissions.defaultMode`); everything else is additive-merged. Don't expand the clobber list without strong justification — the install promise is "we touch only what we have to."

**Plugin dependencies** are added to `scripts/build-plugin.sh` (the `dependencies` array in the manifest). Don't add per-plugin install loops to `install.sh` — chain-install via the manifest does it for free.

**The website** reads `README.md` at build time. Update the README and the site updates automatically on deploy.

## Releasing a New Plugin Version

`VERSION` is the single source of truth for the current version. Never bump it manually or create tags by hand — always use the Makefile:

```bash
make release-patch   # 1.0.1 → 1.0.2
make release-minor   # 1.0.1 → 1.1.0
make release-major   # 1.0.1 → 2.0.0
```

This runs preflight checks (clean tree, on main, in sync with origin), runs E2E tests, bumps `VERSION`, commits, tags, and pushes. GitHub Actions builds the plugin and creates the release.

**Do not** manually edit `VERSION`, create tags with `git tag`, or push tags separately — CI will reject tags that don't match the VERSION file.

## Tests

E2E tests validate the installer across platforms. They run in Docker and on CI.

```bash
make test          # Quick — settings merge + skip behavior (preinstalled suite)
make test-ubuntu   # Full install on clean Ubuntu (main + dev-tools suites)
make test-wsl      # WSL simulation
```

**Test coverage caveat:** Docker images don't include the Claude CLI, so the plugin install branch in `install.sh` is silently skipped during tests. Real validation that plugin install works requires running `curl | bash` on a real machine. Settings merge, idempotency, and the "Claude CLI absent" fallback path are all exercised in Docker.

## Style

- Keep the installer idempotent and safe to re-run.
- Skills are plain Markdown (`SKILL.md`) — no build step.
- Don't add per-project file drops to `install.sh` — that's the plugin's job. `install.sh` only handles things plugins can't (Claude CLI install, profile-level settings).
- The README is the single source of truth for the website.
