# Extras

Optional add-ons that complement the core VibeStack conventions.

## What's Here

| File                   | Description                                    |
| ---------------------- | ---------------------------------------------- |
| `dev-tools/install.sh` | Interactive installer for dev CLIs             |

## Dev Tools Installer

Most platforms ship CLI tools, AWS, Vercel, Supabase, Google Cloud, Stripe, GitHub. Installing them gives your AI agent direct access to manage infrastructure, deployments, databases, and services from the terminal. No clicking through web dashboards, no searching through settings menus. The CLIs are more powerful than most connectors and plugins, and they work across every project on your machine.

This script gets them all set up in one pass:

```bash
./extras/dev-tools/install.sh
```

Every tool is optional, the script prompts before installing anything.

## CI/CD

Project CI setup has moved out of `extras/` and into the `/cicd` skill (see `skills/cicd/`). Run `/cicd` in any project to generate a `.github/workflows/ci.yml` tailored to the project's language stack. Idempotent, re-running reconciles missing language jobs without overwriting existing ones.
