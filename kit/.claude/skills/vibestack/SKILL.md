---
name: vibestack
description: Set up VibeStack conventions for an existing project — fills out CLAUDE.md, Makefile, docs, and TODO.md based on the actual codebase.
user_invocable: true
---

# VibeStack Setup

Analyze the current project and configure all VibeStack files with project-specific content.

## Steps

### 1. Analyze the project

Before changing anything, understand what already exists:

- Read the project's `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `Makefile`, `Dockerfile`, or whatever build/config files exist to determine the tech stack.
- Scan the directory structure to understand how the code is organized.
- Look for existing build, test, run, and deploy scripts or config (npm scripts, Makefile targets, CI workflows, etc.).
- Check for existing documentation, README files, or architecture notes.
- Identify external services (databases, APIs, cloud providers) from config files, `.env*` files, and dependency lists.
- Check for any existing CLAUDE.md content that should be preserved.

### 2. Fill out CLAUDE.md

Update the CLAUDE.md template sections with real project information:

- **Project Overview** — What the project does, core tech, how it's deployed. One paragraph.
- **Tech Stack** — Language, framework, key dependencies, database, infra. Bullet list.
- **Project Structure** — Update the directory tree to match the actual project layout. Keep it to the top-level directories that matter.
- **Architecture** — Key components and how they connect. Be concise.
- **Conventions** — Any conventions you can infer from the code (naming patterns, test organization, error handling style, etc.).

Leave the Commands, Key Workflows, and Skills sections as-is — they describe VibeStack conventions that don't change per project.

### 3. Fill out Makefile

Replace the TODO placeholder commands in the Makefile with real commands based on what you discovered:

- **build** — The actual build command (`npm run build`, `cargo build --release`, `go build`, etc.)
- **test** — The actual test command (`npm test`, `cargo test`, `pytest`, etc.)
- **run** — The actual dev/run command (`npm run dev`, `cargo run`, etc.)
- **deploy** — If you can determine the deploy target (Vercel, AWS, fly.io, etc.), fill it in. Otherwise leave the TODO but add a comment noting what you found.
- **logs** — Same as deploy — fill in if determinable.
- **status** — Same as deploy.
- **docs** — Pick the right doc server if a docs tool is present (mdbook, docusaurus, etc.), otherwise use `python3 -m http.server`.
- **PROJECT_NAME** — Set to the actual project name.

Add any additional project-specific targets that would be useful (e.g., `lint`, `migrate`, `seed`, `typecheck`). Follow the existing pattern — add a new `.PHONY` target with a `## Description` comment for the help output.

**Important:** If a target needs more than a few lines of shell logic, put it in a `scripts/` file and call it from the Makefile target. Keep the Makefile declarative — the scripts folder is where complex bash lives.

### 4. Update the README

The project README should open with a **Commands** section listing all Makefile targets. This is the first thing a developer sees — make it immediately useful.

- **Read the Makefile** and extract all documented targets.
- **Categorize** if there are more than ~6 targets (e.g., "Development", "Testing", "Deployment", "Release"). Flat list is fine for fewer.
- **Order by relevance** — most-used commands first within each category. Development and testing before release and deployment.
- **Use a simple code block** for each command with a one-line description.
- If the README doesn't exist yet, create one with the project name as the title, a one-line description, and the Commands section.
- If a README already exists, add or update the Commands section at the top (after any existing title/badges/description).

### 5. Write initial docs

Based on what you learned about the project, create useful documentation in `docs/`:

- **Create architecture doc** — If the project has enough structure to warrant one (multiple services, clear layers, non-obvious data flow), create `docs/architecture.md` with a high-level overview.
- **Create any topical docs** — If you found non-obvious integration patterns, deployment workflows, or complex subsystems, document them.

Don't create docs just to have docs. Only write what would genuinely help a new contributor (human or AI) get up to speed faster.

### 6. Seed TODO.md

If `TODO.md` doesn't exist, create it. If it already exists and has tasks, skip this step entirely — the user's existing task list takes priority.

If creating from scratch, populate it with a rank-ordered list of the most important engineering tasks to get this application production-ready. Think like a staff engineer driving a small startup toward shipping a rock-solid product — every task should earn its place on the list.

**How to build the list:**

1. Read the project's README, docs/, and any existing documentation first — these often contain product goals, planned features, known limitations, and business context that should inform what matters most. Then audit the codebase for production gaps: missing error handling, no auth, no input validation, missing tests, no CI/CD, no monitoring, hardcoded secrets, no rate limiting, missing database migrations, no logging, etc.
2. Rank tasks by impact — what would block a production launch or erode user trust the fastest? Those go first.
3. Each task should be specific and actionable — not "improve security" but "add rate limiting to public API endpoints" or "move secrets from hardcoded values to environment variables."
4. Group related work but don't nest too deep. A flat, ordered list is better than a complex hierarchy.

**Prioritization order (adapt to what the project actually needs):**

1. **Security & data integrity** — Auth, input validation, secrets management, SQL injection prevention, CSRF protection. Anything that could lose user data or get you hacked.
2. **Core reliability** — Error handling, database migrations, transaction safety, graceful degradation. The app shouldn't crash or corrupt data under normal use.
3. **Testing** — Unit tests for business logic, integration tests for critical paths, E2E tests for key user flows. Enough coverage to deploy with confidence.
4. **CI/CD & deployment** — Automated build/test pipeline, staging environment, zero-downtime deploys. You need to ship fast without breaking things.
5. **Observability** — Logging, error tracking (Sentry etc.), uptime monitoring, basic alerting. You need to know when things break before users tell you.
6. **Performance & scalability** — Database indexing, query optimization, caching, connection pooling. Handle real traffic without falling over.
7. **User experience polish** — Loading states, error messages, edge cases, mobile responsiveness. The stuff that makes users trust your product.
8. **Developer experience** — Linting, type safety, dev environment setup, seed data. Makes the team faster for everything above.

**Guidelines:**
- Aim for 10-20 tasks. Enough to be a real roadmap, not so many it becomes noise.
- Be specific to this codebase — reference actual files, endpoints, or components when possible.
- Don't list things that are already done well. Only gaps and improvements.
- Every item should be completable by a single engineer (or AI agent) in a reasonable scope of work.

### 7. Summary

Tell the user what you set up and what still needs manual attention. Call out:

- What you filled in with confidence
- What you left as TODOs because you couldn't determine the right values
- Any recommendations for next steps
