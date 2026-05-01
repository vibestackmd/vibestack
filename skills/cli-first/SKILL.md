---
name: cli-first
description: Convention for using CLI tools and environment variables when interacting with third-party services like AWS, Vercel, Supabase, Stripe, GitHub, and Google Cloud. Auto-loads when working with external services, deployments, infrastructure, or API integrations.
user-invocable: false
---

# CLI-First Development

When interacting with third-party services, **always prefer CLI tools over web dashboards, REST APIs, or connector plugins.**

## Why CLI First

- CLI tools give you full control over a platform from the terminal — no clicking through dashboard menus
- AI agents can orchestrate complex multi-step workflows (deploy, configure, monitor) through CLIs directly
- CLIs are often more powerful and up-to-date than web UIs or third-party connectors
- Everything stays scriptable, reproducible, and version-controllable

## Environment Variables

Before making API calls or using SDKs directly, **check `.env*` files for existing credentials and project configuration.**

```bash
# Check for environment files in this order:
# 1. .env.local     — local overrides (gitignored, highest priority)
# 2. .env           — shared project defaults
# 3. .env.development / .env.production — environment-specific
```

Look for:
- API keys and access tokens
- Project IDs, org IDs, and region settings
- Database connection strings
- Service-specific configuration (bucket names, queue URLs, etc.)

**Never hardcode credentials.** If a needed credential isn't in `.env*`, ask the user to add it rather than creating one.

## Common CLI Tools

When these CLIs are available, use them instead of raw API calls:

| Service | CLI | Common Uses |
|---------|-----|-------------|
| AWS | `aws` | S3, Lambda, CloudFormation, IAM, ECR, ECS |
| Vercel | `vercel` | Deploy, env vars, domains, project settings |
| Supabase | `supabase` | DB migrations, edge functions, auth config |
| GitHub | `gh` | Issues, PRs, releases, Actions, repo settings |
| Stripe | `stripe` | Webhooks, test events, product/price setup |
| Google Cloud | `gcloud` | Compute, Cloud Run, IAM, storage, pub/sub |
| Firebase | `firebase` | Hosting, Firestore rules, functions |
| Cloudflare | `wrangler` | Workers, KV, R2, DNS |

## Workflow

1. **Check if the CLI is installed** — run `command -v <tool>` or `which <tool>`
2. **Check `.env*` files** for project credentials and configuration
3. **Check auth status** — most CLIs have a `whoami` or `status` command
4. **Use the CLI** to perform the operation instead of visiting the web dashboard
5. **If the CLI isn't installed**, suggest the user install it (see `extras/` for the dev tools installer) rather than working around it with raw HTTP calls

## Examples

```bash
# Instead of visiting the Vercel dashboard to add an env var:
vercel env add MY_SECRET production

# Instead of clicking through AWS console to upload to S3:
aws s3 cp ./dist s3://my-bucket/ --recursive

# Instead of using the Supabase web UI to run a migration:
supabase db push

# Instead of manually creating a GitHub release:
gh release create v1.0.0 --generate-notes

# Instead of configuring Stripe webhooks in the dashboard:
stripe listen --forward-to localhost:3000/api/webhooks
```
