# Fixing CI Failures

A practical guide for fixing CI Guard failures locally. Share this with your team.

## The Checks (Node/TypeScript)

| Check | What it does | How it fails |
|-------|-------------|--------------|
| **Prettier** | Enforces consistent formatting (quotes, semicolons, indentation, etc.) | Any file not matching Prettier's output |
| **ESLint** | Lints for bugs, bad practices, and style issues | Any warning or error (zero-warning policy) |
| **Test Coverage (Jest)** | Runs tests and measures branch/function/line coverage | Coverage below **75%** on branches, functions, or lines |
| **Mutation Testing (Stryker)** | Mutates your code to see if tests actually catch bugs | Mutation score below **60%** (opt-in, off by default) |
| **Security — Trivy** | Scans dependencies for known vulnerabilities | Any HIGH or CRITICAL vulnerability in your deps |
| **Security — gitleaks** | Scans git history for leaked secrets/keys | Any secret-like pattern detected in commits |
| **Code Smells — TODOs** | Blocks `TODO`, `FIXME`, `HACK`, `XXX`, `WORKAROUND` comments | Any match in source files |
| **Code Smells — Unsafe patterns** | Blocks `eval()`, `exec()`, `child_process.exec()`, `dangerouslySetInnerHTML`, `__import__()` | Any match in source files |
| **Large files** | Warns about files >1MB in the repo | Warning only (non-blocking) |

## Fixing Failures with Claude

If you have `claude` installed, you can have it fix most issues automatically. From your project root:

**Formatting (Prettier):**

```bash
# Auto-fix first, then ask Claude about anything weird
npx prettier --write .
```

**Linting (ESLint):**

```bash
# Auto-fix what ESLint can
npx eslint . --fix

# If errors remain, have Claude fix them
claude "Run npx eslint . and fix all remaining errors and warnings"
```

**Test coverage below 75%:**

```bash
# See what's uncovered
npx jest --coverage

# Have Claude write the missing tests
claude "Run the tests with coverage. Look at the uncovered branches and lines and write tests to get coverage above 75%"
```

**Code smells (TODO/FIXME/unsafe patterns):**

```bash
# Have Claude resolve them
claude "Search for TODO, FIXME, HACK, XXX, and WORKAROUND comments in the source code. Resolve each one — either implement the fix or remove the comment with a proper solution."

# For unsafe patterns
claude "Search for eval(), exec(), child_process.exec(), and dangerouslySetInnerHTML in the source code. Refactor each to a safer alternative."
```

**Security vulnerabilities:**

```bash
# See what Trivy finds
npx trivy fs .

# Have Claude help upgrade
claude "Run npx trivy fs . and fix the vulnerabilities by upgrading the affected packages"
```

**General — just throw the CI failure at Claude:**

```bash
# Copy the failing CI log and paste it
claude "Here's my CI failure, fix it: <paste log>"
```

## Tips

- Run `npx prettier --check . && npx eslint . --max-warnings=0` before pushing to catch lint/format issues early
- The CI posts a summary table on your PR — if anything fails, Claude will comment with an explanation of what broke and how to fix it
- Mutation testing is off by default — if it's on for your project and you're stuck, ask Claude: `"My Stryker mutation score is X%. Write better tests to kill the surviving mutants."`
