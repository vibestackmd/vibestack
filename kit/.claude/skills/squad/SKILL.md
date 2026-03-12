---
name: squad
description: Analyze the project and generate domain-specific rules and specialist subagents — breaks a codebase into logical areas so Claude automatically loads the right context for each part.
user_invocable: true
disable-model-invocation: true
argument-hint: "[refresh]"
---

# Squad — Build Your Specialist Team

Analyze the project's codebase and generate path-specific rules and specialist subagents for each logical domain. When Claude later works on files in a domain, the right context loads automatically.

If `$ARGUMENTS` is "refresh", re-analyze and update existing squad config instead of starting from scratch.

## Steps

### 1. Scan the project

Build a mental map of the codebase:

- **Directory structure** — Glob the full project tree (ignore `node_modules`, `.git`, `dist`, `build`, `__pycache__`, `.next`, `vendor`, `target`). Understand how the code is organized at every depth.
- **Entry points** — Find and read main entry files (`index.ts`, `main.py`, `app.ts`, `server.ts`, `cmd/`, etc.) to understand the top-level architecture.
- **Config files** — Read `package.json`, `tsconfig.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, etc. to understand the dependency graph and project boundaries.
- **Import graph** — For the primary language, grep for import/require statements across the codebase. Note which files reference which other files. Files that heavily cross-reference each other belong to the same domain.
- **Types and interfaces** — Find shared type definitions, schemas, models, and interfaces. These often define domain boundaries — a set of types used by a cluster of files signals a domain.

### 2. Identify domains

Group the codebase into **3-8 logical domains**. More than 8 usually means you're slicing too thin. Fewer than 3 means the project might not need squads yet — tell the user and stop.

**How to find domain boundaries:**

- **Feature clusters** — Files that work together to deliver a feature (e.g., auth routes + auth middleware + auth models + auth tests = "auth" domain).
- **Layer boundaries** — Horizontal layers like "data layer", "API surface", "UI components" — but only when they have distinct conventions worth documenting.
- **Infrastructure vs product** — CI/CD, deployment configs, and build tooling are often their own domain.
- **Cross-cutting concerns** — Logging, error handling, and shared utilities may form a domain if they have specific conventions.

**What makes a good domain:**
- Has **specific conventions** that differ from the project defaults (otherwise a rule file adds no value)
- Has **enough files** to warrant its own context (a domain with 2 files isn't worth it)
- Has a **clear identity** — you can name it in 1-2 words and someone knows what it covers

**For each domain, determine:**
- A short name (kebab-case, 1-2 words: `auth`, `data-layer`, `api`, `ui`, `infra`)
- A one-line description
- The glob patterns that cover all its files (can span multiple directories and depths)
- 3-10 bullet points of domain-specific conventions, gotchas, patterns, or rules
- Which other domains it interfaces with (cross-cutting dependencies)
- Whether it's complex enough to warrant a dedicated subagent (most won't — rules are usually sufficient)

### 3. Check for existing squad config

- Read `.claude/squad.json` if it exists (this is the manifest from a previous run).
- If refreshing (`$ARGUMENTS` is "refresh"):
  - Compare the new analysis against existing domains.
  - Identify: new domains to add, existing domains whose patterns need updating, domains that should be removed (files no longer exist).
  - Preserve any manual edits the user made to existing rule files — only update the `paths:` frontmatter and add notes about new files. Do NOT overwrite hand-written convention notes.
- If starting fresh: proceed to generation.

### 4. Generate path-specific rules

For each domain, create a rule file at `.claude/rules/<domain>.md`:

```markdown
---
paths:
  - "src/auth/**/*"
  - "src/middleware/auth*.ts"
  - "tests/auth/**/*"
---

# Auth Domain

One-line description of what this domain covers.

## Conventions

- Bullet points of domain-specific rules
- Patterns that must be followed in these files
- Gotchas or non-obvious behaviors

## Interfaces

- Connects to: data-layer (user sessions), api (route handlers)
- Shared types: `src/types/auth.ts`
```

**Important:**
- Only write conventions that are **specific to this domain** — don't repeat global project rules from CLAUDE.md.
- Be concrete and actionable — "use JWT tokens in httpOnly cookies" not "follow security best practices".
- Include actual file paths and function names when referencing key integration points.
- Glob patterns should be generous enough to catch related test files, type files, and config files — not just source files.

### 5. Generate specialist subagents (selective)

Only generate a subagent for a domain if it meets **all** of these criteria:
- The domain has complex, specialized knowledge (e.g., database migrations, complex build system)
- Getting it wrong has high consequences (e.g., security, data integrity)
- A focused specialist with restricted tools would be safer than the general agent

For qualifying domains, create `.claude/agents/<domain>-specialist.md`:

```markdown
---
name: <domain>-specialist
description: <When Claude should delegate to this specialist>. Use proactively when working on <domain> files.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You are a specialist in <domain> for this project.

<Domain-specific expertise, conventions, and patterns>

When working in this domain:
1. <Specific workflow steps>
2. <What to check before making changes>
3. <How to validate changes>
```

Most domains should get **rules only** (not a subagent). Rules load automatically and are lighter weight. Subagents are for domains where you want Claude to adopt a different persona or use restricted tools.

### 6. Write the manifest

Create or update `.claude/squad.json`:

```json
{
  "generated": "YYYY-MM-DD",
  "domains": {
    "domain-name": {
      "description": "One-line description",
      "patterns": ["glob/patterns/**/*"],
      "ruleFile": ".claude/rules/domain-name.md",
      "agentFile": null,
      "fileCount": 42
    }
  },
  "unmapped": ["files/that/didnt/fit/**"]
}
```

The `unmapped` field lists file patterns that didn't clearly belong to any domain. This helps on refresh — the user (or a future `/squad refresh`) can decide where they belong.

### 7. Summary

Tell the user:

- How many domains were identified (and list them with one-line descriptions)
- How many rule files were generated
- How many subagents were generated (if any)
- Which files are unmapped (if any) and suggestions for where they might belong
- Remind them to review the generated files and tweak conventions — the auto-generated rules are a starting point, not gospel
- Remind them to run `/squad refresh` when the project structure changes significantly

## Guidelines

- **Err toward fewer domains.** It's better to have 4 well-defined domains than 8 thin ones. Users can always split later.
- **Don't repeat CLAUDE.md.** Rules should contain domain-specific knowledge that adds value beyond what's already in the project's CLAUDE.md.
- **Patterns over files.** Use glob patterns, not individual file paths. `src/auth/**/*` is better than listing every file. The pattern should catch future files too.
- **Cross-directory is fine.** A domain can span `src/auth/`, `src/middleware/auth.ts`, `config/auth.json`, and `tests/auth/`. That's the whole point.
- **Be honest about uncertainty.** If you're not sure a file belongs to a domain, put it in `unmapped` rather than guessing wrong.
- **Preserve user edits on refresh.** The auto-generated rules are a starting point. If the user has customized them, preserve those customizations and only update patterns and add notes about new discoveries.
