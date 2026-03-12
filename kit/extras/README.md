# Extras

Optional add-ons that complement the core VibeStack conventions.

## CI Guards

Reusable GitHub Actions workflows that enforce code quality, test coverage, security, and style standards on every PR. Supports Node/TypeScript, Python, Rust, and Go. One command drops a caller workflow into your repo:

```bash
curl -fsSL https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit/extras/ci-guards/install.sh | bash -s -- <language>
```

See [ci-guards/README.md](ci-guards/README.md) for setup details and configuration options.

## What's Here

| File                   | Description                                    |
| ---------------------- | ---------------------------------------------- |
| `dev-tools/install.sh` | Interactive installer for dev CLIs             |
| `ci-guards/install.sh` | CI workflow installer (Node, Python, Rust, Go) |
| `ci-guards/examples/`  | Caller workflow templates for each language    |

## Dev Tools Installer

Most platforms ship CLI tools — AWS, Vercel, Supabase, Google Cloud, Stripe, GitHub. Installing them gives your AI agent direct access to manage infrastructure, deployments, databases, and services from the terminal. No clicking through web dashboards, no searching through settings menus. The CLIs are more powerful than most connectors and plugins, and they work across every project on your machine.

This script gets them all set up in one pass:

```bash
./extras/dev-tools/install.sh
```

Every tool is optional — the script prompts before installing anything.
