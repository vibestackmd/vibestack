# CLAUDE.md

## Project Overview

<!-- One paragraph: what does this project do, what's the core tech, how is it deployed. -->

## Tech Stack

<!-- Bullet list: language, framework, key dependencies, database, infra. -->

## Commands

All operations go through the `Makefile` — the single entry point for build, run, test, and deploy. Run `make help` for the full list.

```bash
make build
make test
make run
make deploy TARGET=prod
make logs TARGET=prod
make status
```

Complex commands that need real bash logic live in `scripts/` and are called from Makefile targets.

## Project Structure

```
src/
docs/           # Living documentation
Makefile        # Project operations — single entry point for all commands
scripts/        # Complex build/deploy scripts called from Makefile
TODO.md         # Task tracking (see TODO Workflow below)
```

## Architecture

<!-- Key components and how they connect. Keep it concise — link to docs/ for deep dives. -->

## Key Workflows

### Docs

The `docs/` folder is the single source of truth for institutional knowledge.

**For AI agents:** Before starting work on an unfamiliar area, check `docs/` for existing context. When you learn something significant during a task — integration quirks, architectural decisions, incident learnings — write it up or update an existing doc. Don't wait to be asked.

- Markdown files organized by topic — one topic per file
- Write as if explaining to a new team member who may be an AI agent

### TODO

`TODO.md` is a lightweight task tracker for human/AI collaboration.

**For AI agents:** Mark items `[~]` (pending) before starting so parallel agents don't collide. Mark `[x]` when done. Start from the top unless told otherwise.

### Skills

VibeStack ships skills at the user level (`~/.claude/skills/`), so they're available in every project on this machine without per-project install.

**Reference skills** (auto-loaded as context):
- `cli-first` — Use CLI tools and `.env*` files for third-party services
- `developer-environment` — Map of what's installed on the machine (languages, runtimes, DBs, cloud CLIs); populates itself on first use
- `lsp` — Use language servers (TypeScript, Python, Rust, Go) for type checking, references, and post-change validation

**Task skills** (invoked via `/command`):
- `/vibestack` — Set up VibeStack conventions for an existing project (CLAUDE.md, Makefile, docs, TODO.md)
- `/docs` — Capture conversation learnings into docs and clean up stale content
- `/todo` — Work through TODO.md tasks sequentially (`/todo refresh` to re-analyze the codebase and rewrite the task list)
- `/squad` — Analyze the project and generate domain-specific rules and specialist subagents (always preserves manual edits; safe to re-run)
- `/bosskey` — Summarize recent git activity into a chill standup script
- `/ideate` — Strategy session with a co-founder persona (read-only; for thinking through ideas before building)

## External Services

This project uses CLI tools for all third-party service interactions. Before using any external API or SDK, check `.env*` files for existing credentials and project configuration. Prefer CLI tools (`aws`, `vercel`, `supabase`, `gh`, `stripe`, `gcloud`, etc.) over web dashboards or raw API calls. See the `cli-first` skill for details.

## Conventions

<!-- Project-specific conventions: naming, commit style, testing approach, error handling, etc. -->
