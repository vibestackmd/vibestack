---
name: vibestack
description: Set up VibeStack conventions for the project in the current directory — creates CLAUDE.md, Makefile, docs/, and TODO.md based on the actual codebase. Skips any of those that already exist. Run this once per project after installing VibeStack at the user level.
user_invocable: true
---

# VibeStack Setup

Scaffold the four VibeStack artifacts in the current project, populated with project-specific content.

The four artifacts:
1. `CLAUDE.md` — project instructions for AI agents
2. `Makefile` — single entry point for build/run/test/deploy
3. `docs/` — living documentation folder
4. `TODO.md` — task tracker

**Idempotent.** If any artifact already exists, leave it untouched and tell the user — don't overwrite their work.

Source templates live alongside this skill:
- `${CLAUDE_SKILL_DIR}/templates/CLAUDE.md`
- `${CLAUDE_SKILL_DIR}/templates/Makefile`

Read those templates as the structural starting point, then fill in project-specific content.

## Steps

### 1. Analyze the project

Before changing anything, understand what already exists:

- Read `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Dockerfile`, or any build/config files to determine the tech stack.
- Scan the directory structure to understand how the code is organized.
- Look for existing build, test, run, and deploy scripts (npm scripts, Makefile targets, CI workflows).
- Check for existing README, docs, or architecture notes.
- Identify external services from `.env*` files and dependencies.
- Note which of the four artifacts already exist — those are skipped.

### 2. Create CLAUDE.md (if missing)

Read the template at `${CLAUDE_SKILL_DIR}/templates/CLAUDE.md`. Use it as the structural starting point and fill in:

- **Project Overview** — One paragraph: what the project does, core tech, deployment.
- **Tech Stack** — Bullet list: language, framework, key dependencies, database, infra.
- **Project Structure** — Directory tree matching the actual layout (top-level only).
- **Architecture** — Key components and how they connect. Concise.
- **Conventions** — Inferred from the code (naming, test organization, error handling style).

Leave the Commands, Key Workflows, and Skills sections as-is — they describe VibeStack conventions that don't change per project.

### 3. Create Makefile (if missing)

Read the template at `${CLAUDE_SKILL_DIR}/templates/Makefile`. Replace the TODO placeholders with real commands:

- **build** — `npm run build`, `cargo build --release`, `go build`, etc.
- **test** — `npm test`, `cargo test`, `pytest`, etc.
- **run** — `npm run dev`, `cargo run`, etc.
- **deploy** — Determine deploy target from config (Vercel, AWS, fly.io). If unclear, leave a TODO with what you found.
- **logs**, **status** — Same approach as deploy.
- **docs** — Pick the right doc server if present (mdbook, docusaurus), otherwise `python3 -m http.server`.
- **PROJECT_NAME** — Real project name.

Add project-specific targets that would be useful (`lint`, `migrate`, `seed`, `typecheck`). Follow the existing pattern — `.PHONY` target with a `## Description` comment for help output.

If a target needs more than a few lines of shell, put it in `scripts/` and call it from the Makefile.

### 4. Update the README

The README should open with a **Commands** section listing all Makefile targets:

- Read the new Makefile and extract all documented targets.
- Categorize if more than ~6 (Development, Testing, Deployment, Release). Flat list otherwise.
- Order by relevance — most-used first within each category.
- One-line description per command, in a code block.
- If no README exists, create one with the project name as the title, a one-line description, and the Commands section.
- If a README already exists, add or update the Commands section near the top (after title/badges/intro).

### 5. Create docs/ (if missing)

Create the folder and seed it only with what's genuinely useful:

- **`docs/architecture.md`** — Only if the project has enough structure to warrant one (multiple services, clear layers, non-obvious data flow).
- **Topical docs** — Only for non-obvious integration patterns, deployment workflows, or complex subsystems.

Don't create docs just to have docs. Empty placeholders aren't useful — only ship a doc if it would actually help a contributor get up to speed.

### 6. Create TODO.md (if missing)

Start with this header:

```
# TODO

AGENTS: When prompted, complete tasks from the list below. Before starting work, mark the item as pending `[~]` so parallel agents don't collide. After completion, mark it `[x]`. Start at the top unless the user specifies otherwise.

## Backlog
```

Then populate with 10-20 rank-ordered tasks. Think like a staff engineer driving a small startup toward a rock-solid production application — every task should earn its place.

**Prioritization order (adapt to what the project actually needs):**

1. **Security & data integrity** — Auth, input validation, secrets management, SQL injection prevention, CSRF protection.
2. **Core reliability** — Error handling, database migrations, transaction safety, graceful degradation.
3. **Testing** — Unit tests for business logic, integration tests for critical paths, E2E for key flows.
4. **CI/CD & deployment** — Automated build/test pipeline, staging environment, zero-downtime deploys.
5. **Observability** — Logging, error tracking, uptime monitoring, basic alerting.
6. **Performance & scalability** — Indexing, query optimization, caching, connection pooling.
7. **User experience polish** — Loading states, error messages, edge cases, mobile responsiveness.
8. **Developer experience** — Linting, type safety, dev environment setup, seed data.

**Guidelines:**
- Each task: specific and actionable. Reference actual files, endpoints, or components.
- Each task: completable by a single engineer (or AI agent) in a reasonable scope.
- Don't list things already done well. Only gaps and improvements.

### 7. Summary

Tell the user what you did:

- Which of the four artifacts you created
- Which already existed and were left untouched
- What you filled in with confidence
- What you left as TODOs because you couldn't determine the right values
- Recommended next steps (e.g., "review CLAUDE.md", "run /todo to start working through the list")
