# VibeStack

Opinionated project structure, skills, and tooling for AI-assisted development. This doc explains the conventions and how to get the most out of them.

## How It All Fits Together

```
CLAUDE.md           # Quick-reference card — what this project is, how to build/run/test
Makefile            # All project operations: make build, make test, make deploy
scripts/            # Complex bash logic called from Makefile targets
TODO.md             # Task tracker with a protocol for parallel AI agents
docs/               # Living knowledge base — you're reading one now
.claude/
  skills/           # Teach Claude your project's conventions and workflows
  hooks/            # Automation — finish notifications, status line
  settings.json     # Permissions, env vars, tool config
```

**CLAUDE.md** is the entry point. Every contributor — human or AI — reads it first. Keep it concise: what the project does, how to run it, key conventions. The `/vibestack` skill fills it out automatically.

## Makefile

All project operations go through the Makefile. No custom CLI, no bespoke shell script — just `make`.

```bash
make build          # Build the project
make test           # Run tests
make deploy TARGET=prod
make help           # Show all available targets
```

**Convention:** keep Makefile targets thin and declarative. If a target needs more than a few lines of shell, put the logic in `scripts/` and call it from the target:

```makefile
deploy: ## Deploy to a target
	bash scripts/deploy.sh $(TARGET)
```

This keeps the Makefile readable while letting complex operations live in proper bash scripts with error handling, functions, and all the expressiveness you need.

Run `make help` to see all available targets — every target with a `## comment` is self-documenting.

## TODO.md

Lightweight task tracker designed for human/AI collaboration.

- `[ ]` — unclaimed, ready to work
- `[~]` — claimed by an agent (don't touch)
- `[x]` — done

AI agents claim tasks from the top down by marking them `[~]` before starting. This prevents collisions when multiple agents work in parallel. Run `/todo` to work through tasks, or `/todo populate` to analyze the codebase and seed the next batch ranked by impact.

## Docs

The `docs/` folder is the project's institutional memory. One markdown file per topic. Write docs when you discover something non-obvious — API quirks, architectural decisions, incident postmortems, integration gotchas. The docs you write today prevent your AI from re-discovering the same lessons tomorrow.

**For AI agents:** check `docs/` before starting work on an unfamiliar area. When you learn something significant during a task, write it up. Don't wait to be asked.

## Skills

Skills are markdown files in `.claude/skills/` that teach Claude project-specific conventions and give it repeatable workflows.

### Reference Skills (auto-loaded)

Background knowledge Claude loads when relevant. No slash command — just context.

```
.claude/skills/api-conventions/SKILL.md
.claude/skills/testing-patterns/SKILL.md
```

Set `user_invocable: false` and write a clear `description` so Claude knows when to load it. Use these when you find yourself repeatedly explaining the same convention.

### Task Skills (slash commands)

Repeatable workflows triggered with `/skill-name`.

```
.claude/skills/deploy-staging/SKILL.md    → /deploy-staging
.claude/skills/fix-issue/SKILL.md         → /fix-issue 123
```

Set `disable-model-invocation: true` so only you can trigger them.

### Writing a Skill

Every skill lives in `.claude/skills/<name>/SKILL.md` with YAML frontmatter:

```yaml
---
name: my-skill
description: What this skill does and when Claude should use it
user_invocable: true
disable-model-invocation: true
argument-hint: "[args]"
---

Instructions for Claude to follow.
Use $ARGUMENTS for the full user input, $0, $1, $2 for positional args.
```

| Field | Purpose |
|-------|---------|
| `name` | Slash command name (lowercase, hyphens) |
| `description` | When Claude should use/load this skill |
| `user_invocable` | `true` for slash commands, `false` for reference skills |
| `disable-model-invocation` | Only the user can trigger it |
| `allowed-tools` | Pre-approve tools (e.g. `Read, Grep, Bash(cargo *)`) |
| `argument-hint` | Autocomplete hint shown in the `/` menu |

Project skills live in `.claude/skills/`. Personal skills in `~/.claude/skills/` (personal overrides project).

### Included Skills

**Reference** (auto-loaded):
- `cli-first` — Use CLI tools and `.env*` files for third-party service access
- `lsp` — Use language servers for type checking, go-to-definition, find-references

**Task** (slash commands):
- `/vibestack` — Analyze the project and fill out CLAUDE.md, Makefile, docs, TODO.md
- `/squad` — Generate domain-specific rules and specialist subagents for large codebases
- `/todo` — Work through TODO.md tasks sequentially
- `/docs` — Capture conversation learnings into docs, clean up stale content
