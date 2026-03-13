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
| `make release` | Tag + push a release (triggers GitHub Actions) |
| `make test` | Run quick E2E tests |
| `make test-ubuntu` | Full Ubuntu install test (Docker) |
| `make test-wsl` | WSL simulation test (Docker) |
| `make clean` | Remove build artifacts |

## Project Structure

```
install.sh              # Main installer (curl | bash entry point)
kit/                    # Files that get installed into user projects
  .claude/skills/       # Skills (vibestack, todo, squad, docs, cli-first, lsp)
  .claude/hooks/        # Hooks (notify-done, statusline)
  .claude/settings.json # Default settings
  docs/                 # Documentation templates
  extras/               # Optional add-ons (ci-guards, dev-tools)
site/                   # Website (Next.js, deployed to vibestack.md)
tests/e2e/              # End-to-end install tests
scripts/                # Build scripts
VERSION                 # Plugin version (semver, no v prefix)
Makefile                # Developer commands
```

## Making Changes

**Skills and hooks** live in `kit/.claude/`. Edit them there — they're copied into the plugin during `make plugin` and served to users via `install.sh`.

**The website** reads `README.md` at build time. Update the README and the site updates automatically on deploy.

**The installer** (`install.sh`) downloads files from `kit/` on GitHub. Changes to `kit/` are live as soon as they're pushed to `main`.

## Releasing a New Plugin Version

1. Update `VERSION` (e.g., `0.1.0` → `0.2.0`)
2. Commit: `git commit -am "bump version to 0.2.0"`
3. Run `make release` — tags and pushes, GitHub Actions builds the plugin and creates a release

## Tests

E2E tests validate the installer across platforms. They run in Docker and on CI.

```bash
make test          # Quick — main installer + skip behavior
make test-ubuntu   # Full install on clean Ubuntu
make test-wsl      # WSL simulation
```

## Style

- Keep the installer idempotent and safe to re-run
- Every tool prompt is optional — nothing installs without asking
- Skills are plain Markdown (`SKILL.md`) — no build step needed
- The README is the single source of truth for the website
