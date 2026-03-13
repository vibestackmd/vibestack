---
name: lsp
description: Convention for using language server tools (LSP) to get precise type info, find references, check diagnostics, and navigate definitions across files. Auto-loads when doing refactors, debugging type errors, or working across multiple files.
user-invocable: false
---

# LSP-Assisted Code Intelligence

When working across multiple files, refactoring, or debugging type errors, **use language server tools to get precise answers instead of guessing from grep results.**

## When to Reach for LSP

- **Finding all references** to a function, type, or variable across the codebase
- **Go-to-definition** when you need to understand what a symbol actually is
- **Type checking** before declaring a refactor "done" — catch errors the way CI will
- **Understanding inferred types** that aren't written explicitly in source code
- **Call hierarchy** — who calls this function? What does this function call?
- **Rename safety** — verify all usages before a cross-file rename

Don't bother for simple, single-file edits where you can read the code directly.

## Tools by Language

### TypeScript / JavaScript → `typescript-language-server` + `tsc`

```bash
# Type-check a project (catches errors across all files)
npx tsc --noEmit

# Type-check and get structured output
npx tsc --noEmit --pretty 2>&1
```

LSP (via the LSP tool if available):
- `textDocument/hover` — get the inferred type of any symbol
- `textDocument/definition` — jump to where a symbol is defined
- `textDocument/references` — find every usage of a symbol
- `textDocument/rename` — safe cross-file rename with all usages
- `textDocument/signatureHelp` — get function parameter info
- `workspace/symbol` — search for symbols by name across the project

### Python → `pyright`

```bash
# Full type-check (structured JSON output — preferred)
pyright <file-or-directory> --outputjson

# Human-readable output
pyright <file-or-directory>

# Check a single file quickly
pyright src/auth/handler.py
```

Pyright catches: missing imports, wrong argument types, unresolved attributes, incorrect return types, None-safety issues.

### Rust → `rust-analyzer` + `cargo`

```bash
# Type-check the project (structured output)
cargo check --message-format=json 2>&1

# Human-readable
cargo check 2>&1

# Run clippy for deeper analysis (lint + type issues)
cargo clippy --message-format=json 2>&1
```

LSP (via the LSP tool if available):
- All standard LSP methods plus Rust-specific: trait implementations, macro expansion, lifetime analysis

### Go → `gopls` + `go`

```bash
# Type-check / vet
go vet ./...

# Build check without producing binary
go build ./...
```

LSP (via the LSP tool if available):
- All standard LSP methods plus Go-specific: interface implementations, package symbol search

## Workflow

1. **Before a cross-file refactor** — use references/definition to map the blast radius
2. **During implementation** — use hover/signatureHelp when unsure about types or APIs
3. **After changes** — run the type checker (`tsc --noEmit`, `pyright`, `cargo check`, `go vet`) to verify correctness before reporting done
4. **Parse output yourself** — extract only the relevant diagnostics. Don't dump raw JSON at the user

## Rules

- **Prefer LSP over grep for semantic queries.** Grep finds text; LSP understands code. "Find all references to `UserSession`" via LSP won't false-match comments or strings.
- **Prefer CLI type-checkers for validation.** After making changes, run the project's type checker. This catches what reading files alone cannot.
- **Scope narrowly.** Check one file or directory first, not the whole project, unless you need full-project diagnostics.
- **Never hallucinate types.** If you're unsure about an inferred type or function signature, query the tool — don't guess.
