# CI Guards

Reusable GitHub Actions workflows that enforce code quality, test coverage, security, and style standards. Drop a tiny `ci.yml` into any repo and get instant, language-specific quality gates.

Part of [VibeStack](../../README.md) extras.

## What It Enforces

| Check | What It Does | Default Threshold |
|-------|-------------|-------------------|
| **Lint & Format** | Language-specific linter + formatter | Zero warnings |
| **Test Coverage** | Branch coverage via tests | 75% |
| **Mutation Testing** | Catches fake/shallow tests | 60% (opt-in) |
| **Security Scan** | Trivy (deps) + gitleaks (secrets) | Fail on HIGH+ |
| **Code Smells** | Blocks TODO/FIXME, eval(), exec(), etc. | Strict |
| **AI Teaching** | Claude-powered failure explanations on PRs | Enabled |
| **SonarCloud** | Unified code health score (optional) | Configurable |

## Quick Start

### 1. Allow Workflow Access

In the `shared-ci-guards` repo, go to **Settings > Actions > General > Access** and select "Accessible from repositories in the organization" (or make the repo public).

### 2. Add Secrets to Your Project Repo

| Secret | Required For | Where to Get It |
|--------|-------------|-----------------|
| `ANTHROPIC_API_KEY` | AI teaching feedback | [console.anthropic.com](https://console.anthropic.com) |
| `SONAR_TOKEN` | SonarCloud quality gate | [sonarcloud.io](https://sonarcloud.io) |

### 3. Add a Caller Workflow

Run one of the install commands below from your project root. It creates `.github/workflows/ci.yml` with the right caller workflow.

#### One-line install

Node / TypeScript:
```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/install.sh | bash -s -- node
```

Python:
```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/install.sh | bash -s -- python
```

Rust:
```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/install.sh | bash -s -- rust
```

Go:
```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/install.sh | bash -s -- go
```

Custom output path:
```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/install.sh | bash -s -- node -o .github/workflows/ci-node.yml
```

#### Or curl the workflow directly

First, ensure the directory exists:
```bash
mkdir -p .github/workflows
```

Node / TypeScript:
```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/examples/node-caller.yml -o .github/workflows/ci.yml
```

Python:
```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/examples/python-caller.yml -o .github/workflows/ci.yml
```

Rust:
```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/examples/rust-caller.yml -o .github/workflows/ci.yml
```

Go:
```bash
curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/ci-guards/examples/go-caller.yml -o .github/workflows/ci.yml
```


<details>
<summary>What gets installed (example: Node)</summary>

```yaml
name: CI
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  quality-gate:
    uses: vibestackmd/shared-ci-guards/.github/workflows/ci-node.yml@main
    with:
      node-version: "20"
      coverage-threshold: 75
      # mutation-enabled: true   # opt-in — adds ~5-15 min
      # mutation-score: 60       # minimum mutants killed %
      # working-directory: "."   # change for monorepos
      # enable-ai-feedback: true # Claude explains failures
    secrets: inherit
```

</details>

### 4. Lock Down `main`

In your project repo: **Settings > Branches > Add rule**

- Branch name pattern: `main`
- Check "Require a pull request before merging"
- Check "Require status checks to pass before merging"
- Select the CI jobs as required checks
- Check "Do not allow bypassing the above settings"

## Workflow Reference

### Language Guards

All language workflows accept these common inputs:

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `coverage-threshold` | number | `75` | Minimum test coverage % |
| `mutation-enabled` | boolean | `false` | Enable mutation testing |
| `mutation-score` | number | `60` | Minimum mutation score % |
| `working-directory` | string | `.` | For monorepos |
| `enable-ai-feedback` | boolean | `true` | AI failure explanations |

Plus language-specific inputs (version, package manager, etc.) — see each workflow file.

### Standalone Workflows

These are called automatically by the language guards, but can also be used independently:

#### `security-scan.yml`

```yaml
jobs:
  security:
    uses: vibestackmd/shared-ci-guards/.github/workflows/security-scan.yml@main
    with:
      severity: "HIGH"  # CRITICAL, HIGH, MEDIUM, LOW
```

#### `no-smell-check.yml`

```yaml
jobs:
  smells:
    uses: vibestackmd/shared-ci-guards/.github/workflows/no-smell-check.yml@main
    with:
      block-todo: true
      block-unsafe-patterns: true
```

#### `ai-teaching.yml`

Requires `ANTHROPIC_API_KEY` secret. Posts a Claude-generated PR comment explaining failures.

#### `code-quality.yml` (SonarCloud)

```yaml
jobs:
  sonar:
    uses: vibestackmd/shared-ci-guards/.github/workflows/code-quality.yml@main
    with:
      project-key: "my-org_my-repo"
      organization: "my-org"
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## What Happens on a PR

1. Dev opens PR against `main`
2. Language-specific checks run in parallel (lint, test, security, smells)
3. If anything fails, Claude reads the diff + errors and posts a friendly comment explaining what broke and how to fix it
4. A summary table is posted/updated on the PR showing all check results
5. PR cannot merge until all required checks pass

## Tuning Thresholds

Start here, tighten over time:

| Metric | Starting | Mature | Aggressive |
|--------|----------|--------|------------|
| Coverage | 75% | 85% | 90%+ |
| Mutation | 60% | 70% | 80%+ |
| Complexity | off | 10/fn | 8/fn |

## Tools Used

| Language | Formatter | Linter | Test | Coverage | Mutation |
|----------|-----------|--------|------|----------|----------|
| Node/TS | Prettier | ESLint | Jest | Jest --coverage | Stryker |
| Python | Ruff | Ruff | pytest | pytest-cov | mutmut |
| Rust | rustfmt | Clippy | cargo test | cargo-tarpaulin | cargo-mutants |
| Go | gofmt | golangci-lint | go test | go test -cover | go-mutesting |

Security: Trivy + gitleaks (all languages)
AI Feedback: Claude (Anthropic API)
Code Quality: SonarCloud (optional)

## Notes

- **gitleaks on private repos** requires a [gitleaks license](https://gitleaks.io/) or a `GITLEAKS_LICENSE` secret. On public repos it works for free.
- **The reusable workflows live in the [shared-ci-guards](https://github.com/vibestackmd/shared-ci-guards) repo** on GitHub. The caller YMLs installed by this script reference them via `uses: vibestackmd/shared-ci-guards/.github/workflows/...@main`. That repo must be public (or accessible within your GitHub org) for the references to work.
