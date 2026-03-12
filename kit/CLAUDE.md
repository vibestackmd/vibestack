# CLAUDE.md

## Project Overview

<!-- One paragraph: what does this project do, what's the core tech, how is it deployed. -->

## Tech Stack

<!-- Bullet list: language, framework, key dependencies, database, infra. -->

## Commands

All operations go through `ops.sh` — the single entry point for build, run, test, and deploy. Run `./ops.sh help` for the full list.

```bash
./ops.sh build
./ops.sh test
./ops.sh run
./ops.sh deploy <target>
./ops.sh logs <target>
./ops.sh status
```

## Project Structure

```
src/
docs/           # Living documentation (see docs/README.md)
ops.sh          # Project CLI — single entry point for all operations
TODO.md         # Task tracking (see TODO Workflow below)
.claude/
  skills/       # Claude skills — conventions and slash commands
```

## Architecture

<!-- Key components and how they connect. Keep it concise — link to docs/ for deep dives. -->

## Key Workflows

### Docs

The `docs/` folder is the single source of truth for institutional knowledge. See `docs/README.md` for the full convention.

**For AI agents:** Before starting work on an unfamiliar area, check `docs/` for existing context. When you learn something significant during a task — integration quirks, architectural decisions, incident learnings — write it up or update an existing doc. Don't wait to be asked.

- Markdown files organized by topic in subdirectories
- `docs/SUMMARY.md` is the table of contents — update it when adding or removing docs
- Write as if explaining to a new team member who may be an AI agent

### TODO

`TODO.md` is a lightweight task tracker for human/AI collaboration.

**For AI agents:** Mark items `[~]` (pending) before starting so parallel agents don't collide. Mark `[x]` when done. Start from the top unless told otherwise.

### Skills

`.claude/skills/` teaches Claude project-specific conventions and provides reusable workflows as slash commands. See `docs/skills-and-commands.md` for how to create new ones.

**Reference skills** (auto-loaded as context):
- `cli-first` — Use CLI tools and `.env*` files for third-party services

**Task skills** (invoked via `/command`):
- `/vibestack` — Set up vibestack conventions for an existing project (CLAUDE.md, ops.sh, docs, TODO.md)
- `/docs` — Capture conversation learnings into docs and clean up stale content
- `/todo` — Work through TODO.md tasks sequentially (`/todo populate` to re-analyze the codebase and seed the next batch of tasks)
- `/squad` — Analyze the project and generate domain-specific rules and specialist subagents (`/squad refresh` to update)

## External Services

This project uses CLI tools for all third-party service interactions. Before using any external API or SDK, check `.env*` files for existing credentials and project configuration. Prefer CLI tools (`aws`, `vercel`, `supabase`, `gh`, `stripe`, `gcloud`, etc.) over web dashboards or raw API calls. See the `cli-first` skill for details.

## Conventions

<!-- Project-specific conventions: naming, commit style, testing approach, error handling, etc. -->
