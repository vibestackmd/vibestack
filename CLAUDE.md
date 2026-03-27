# CLAUDE.md

## Project Overview

VibeStack is a Claude Code plugin that gives AI agents project structure, skills, and conventions. It installs into user projects via `curl | bash` and is also distributed as a Claude Code plugin.

## Tech Stack

- **Site:** Next.js (in `site/`)
- **Plugin/Kit:** Plain Markdown skills, bash hooks, JSON config (in `kit/`)
- **Installer:** Bash (`install.sh`)
- **Tests:** E2E bash tests, run in Docker for cross-platform coverage
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
install.sh              # Main installer (curl | bash entry point)
kit/                    # Files installed into user projects
  .claude/skills/       # Skills (vibestack, todo, squad, docs, cli-first, lsp)
  .claude/hooks/        # Hooks (notify-done, statusline)
  .claude/settings.json # Default settings
  docs/                 # Documentation templates
  extras/               # Optional add-ons
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

## Conventions

- Keep the installer idempotent and safe to re-run
- Skills are plain Markdown (`SKILL.md`) — no build step
- `kit/CLAUDE.md` is a template for user projects, not this repo's CLAUDE.md
- The README is the single source of truth for the website
