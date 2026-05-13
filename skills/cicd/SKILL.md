---
name: cicd
description: Set up a self-contained GitHub Actions CI workflow for the current project. Detects language(s) from the codebase (TS/JS, Python, Go, Rust) and writes `.github/workflows/ci.yml` with lint, test, and build gates. Idempotent, skips if the workflow already exists unless the user asks to reconcile.
user_invocable: true
---

# CI/CD Setup

Generate a self-contained `.github/workflows/ci.yml` tailored to the project's language stack. The workflow runs on every PR and on pushes to `main`, with lint + test + (optional) build gates.

**Self-contained.** No external reusable workflows, no shared repos. Each project owns its CI file outright.

**Idempotent.** If `.github/workflows/ci.yml` already exists, do not overwrite. Tell the user it exists, show its language coverage, and ask whether to reconcile (add missing language jobs) or leave it.

## Steps

### 1. Detect the language stack

Read the repo root and identify which of the supported languages are in play. Look for these markers (a project can be polyglot, generate jobs for every language found):

| Language | Marker files |
|---|---|
| Node / TypeScript | `package.json` (check `engines.node`, scripts, lockfile for npm/pnpm/yarn/bun) |
| Python | `pyproject.toml`, `requirements.txt`, `setup.py`, `Pipfile` |
| Go | `go.mod` |
| Rust | `Cargo.toml` |

If none of these are present, tell the user the project's language stack isn't recognized and stop. Don't write a workflow that won't work.

If multiple languages are detected, generate a workflow with one job per language. The jobs run in parallel.

### 2. Check for existing workflow

If `.github/workflows/ci.yml` exists:
- Read it.
- Identify which languages it covers (look for `setup-node`, `setup-python`, `setup-go`, `dtolnay/rust-toolchain`).
- If it already covers everything detected in step 1, tell the user "CI workflow already in place for [languages]; nothing to do" and stop.
- If it's missing language(s), offer to add jobs for the missing ones. Don't rewrite existing jobs.

If no workflow exists, proceed to generate one.

### 3. Generate the workflow

Assemble `.github/workflows/ci.yml` from the snippets below. Use a single `name: CI` header and one job per detected language. Each job runs on `ubuntu-latest`.

**Common header:**

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
```

**Node / TypeScript job.** Detect the package manager from the lockfile (`pnpm-lock.yaml` → pnpm; `yarn.lock` → yarn; `bun.lockb` → bun; otherwise → npm). Adjust the install + run lines accordingly. Use `--if-present` for scripts so the job doesn't fail when a script isn't defined.

```yaml
  node:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'  # change to pnpm/yarn if detected
      - run: npm ci
      - run: npm run lint --if-present
      - run: npm run typecheck --if-present
      - run: npm test --if-present
      - run: npm run build --if-present
```

**Python job.** Default to pip + pyproject.toml. If `poetry.lock` is present use poetry; if `uv.lock` is present use uv. Run ruff if `ruff` appears in pyproject deps or `ruff.toml`/`.ruff.toml` exists. Run pytest unconditionally, the project will fail-fast if no tests exist, which is fine.

```yaml
  python:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'
      - run: pip install -e ".[dev]" || pip install -r requirements.txt
      - run: ruff check .
        if: ${{ hashFiles('ruff.toml', '.ruff.toml') != '' || contains(fromJSON('[true]'), false) }}
      - run: pytest
```

(If the ruff conditional is too clever, just emit a plain `ruff check . || true`, getting a real ruff signal matters more than perfect conditional gating.)

**Go job.** Read `go.mod` for the module's Go version directive and use it.

```yaml
  go:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version-file: 'go.mod'
      - run: go vet ./...
      - run: go test ./...
      - run: go build ./...
```

**Rust job.**

```yaml
  rust:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy, rustfmt
      - uses: Swatinem/rust-cache@v2
      - run: cargo fmt --check
      - run: cargo clippy -- -D warnings
      - run: cargo test
      - run: cargo build
```

### 4. Write the file

Create `.github/workflows/` if it doesn't exist, then write the assembled YAML to `.github/workflows/ci.yml`. Don't add a trailing newline beyond the standard single one.

### 5. Tell the user what you did

Report:
- Languages detected and the corresponding jobs added.
- Package manager detected for Node (npm/pnpm/yarn/bun), important so they know what `npm ci` resolved to.
- File path written.
- Whether anything was skipped (e.g., workflow already existed and covered everything).
- Next step: commit, push, and open a PR to see the workflow run.

If the project uses an unusual setup (custom test commands, non-standard layout, monorepo with multiple packages), flag it, the generated workflow assumes the project root holds the package config. Suggest manual edits if that doesn't hold.

## What this skill does NOT do

- Coverage thresholds (each language ecosystem has its own tooling; opt in per-project).
- Security scans (Trivy, gitleaks). Add them later if the project's threat model needs it.
- Deploy steps. Deploy belongs in a separate workflow keyed to the project's hosting platform, not in `ci.yml`.
- Mutation testing. Niche.
- AI-powered failure feedback. Cool, but cross-cutting concern.

Keep the generated workflow lean. Projects grow into more later; they shouldn't start there.
