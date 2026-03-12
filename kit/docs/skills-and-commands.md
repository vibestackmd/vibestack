# Skills & Slash Commands

Claude Code supports custom skills that teach it project-specific conventions and give it reusable workflows.

## Two Types of Skills

### Reference Skills (Auto-Loaded Context)

Teach Claude *how your project works*. Claude reads the `description` field and auto-loads the skill when relevant.

```
.claude/skills/error-handling/SKILL.md
.claude/skills/api-conventions/SKILL.md
.claude/skills/testing-patterns/SKILL.md
```

**When to use:** You find yourself repeatedly explaining the same convention to Claude. Write it once as a skill and it'll know going forward.

**Key settings:**
- `user-invocable: false` — no slash command, just background knowledge
- Write a clear `description` so Claude knows when to load it

### Task Skills (Slash Commands)

Give Claude a *repeatable workflow* you trigger with `/skill-name`.

```
.claude/skills/deploy-staging/SKILL.md    -> /deploy-staging
.claude/skills/audit-module/SKILL.md      -> /audit-module src/auth
.claude/skills/fix-issue/SKILL.md         -> /fix-issue 123
```

**When to use:** You have a multi-step workflow you run regularly (deploy, review, migrate, audit).

**Key settings:**
- `disable-model-invocation: true` — only you can trigger it
- `allowed-tools` — pre-approve specific tools so Claude doesn't ask each time
- `argument-hint` — shows what args to pass in autocomplete

## File Structure

```
.claude/skills/
  my-skill/
    SKILL.md          # Required — frontmatter + instructions
    reference.md      # Optional — detailed docs Claude can read
    templates/        # Optional — templates, examples, scripts
```

Every `SKILL.md` has YAML frontmatter and markdown content:

```yaml
---
name: my-skill
description: What this skill does and when Claude should use it
---

# Instructions

The actual content Claude follows.
Use $ARGUMENTS for user input when invoked as /my-skill <args>.
Use $0, $1, $2 for positional args.
```

## Frontmatter Reference

| Field | Purpose | Example |
|-------|---------|---------|
| `name` | Slash command name (lowercase, hyphens) | `fix-issue` |
| `description` | When Claude should use this | `"Fix GitHub issues by number"` |
| `disable-model-invocation` | Only user can trigger | `true` |
| `user-invocable` | Show in `/` menu | `false` for reference skills |
| `allowed-tools` | Pre-approve tools | `Read, Grep, Bash(cargo *)` |
| `argument-hint` | Autocomplete hint | `[issue-number]` |
| `context` | Run in isolation | `fork` |

## Arguments

When someone types `/fix-issue 123 --verbose`:

| Variable | Value |
|----------|-------|
| `$ARGUMENTS` | `123 --verbose` |
| `$0` | `123` |
| `$1` | `--verbose` |

If `$ARGUMENTS` isn't used in the skill content, Claude Code appends it automatically.

## Where Skills Live

| Location | Scope |
|----------|-------|
| `.claude/skills/` | This project only |
| `~/.claude/skills/` | All your projects (personal) |

Personal skills override project skills with the same name.

## Included Skills

This kit ships with skills you can use as-is or as examples for writing your own:

**Reference skills** (auto-loaded as context):
- `cli-first` — Convention for using CLI tools and environment variables when interacting with third-party services. Auto-loads when working with external services, deployments, or infrastructure.

**Task skills** (invoked via `/command`):
- `/vibestack` — Set up VibeStack conventions for an existing project. Analyzes the codebase to fill out CLAUDE.md, ops.sh, docs, and TODO.md with project-specific content. Run this after installing the kit into a repo.
- `/docs` — Captures conversation learnings into docs and cleans up the docs folder. Reviews the conversation for decisions, architectural changes, and insights worth preserving, then writes them to the right place in `docs/`. Also scans for stale references, redundancy, and outdated examples.
- `/todo` — Works through TODO.md tasks sequentially. Reads the file, claims uncompleted items, executes them, and marks them done. Optionally pass a number to limit how many tasks to run (e.g., `/todo 3`). Use `/todo populate` to re-analyze the codebase and seed the next batch of highest-impact tasks — it clears completed items, preserves in-progress work, and adds 10-20 new rank-ordered tasks prioritized by production readiness.
