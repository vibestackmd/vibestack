# Dev Tools Installer

Interactive installer that sets up a developer environment for AI-assisted development. Works on **macOS** and **Linux/WSL Ubuntu**. Each tool is optional — the script prompts before installing anything.

Part of [VibeStack](../../README.md) extras.

## Quick Start

**macOS / Linux / WSL:**

```bash
curl -fsSL https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit/extras/dev-tools/install.sh | bash
```

**Windows (sets up WSL + Ubuntu first, then runs the installer):**

```powershell
# Run in PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
.\bootstrap-windows.ps1
```

Or if you haven't cloned the repo:

```powershell
# Download and run
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit/extras/dev-tools/bootstrap-windows.ps1" -OutFile "$env:TEMP\bootstrap-windows.ps1"
(Get-Content "$env:TEMP\bootstrap-windows.ps1" -Raw) | Set-Content "$env:TEMP\bootstrap-windows.ps1"
powershell -ExecutionPolicy Bypass -File "$env:TEMP\bootstrap-windows.ps1"
```

Safe to re-run — already-installed tools and active logins are automatically skipped.

## What It Installs

| Tool | macOS | Linux/WSL | Why |
|------|-------|-----------|-----|
| **Linux Prerequisites** | — | apt (curl, unzip, gpg, build-essential) | Essential build tools |
| **Zsh** | — (default shell) | apt | Modern shell with better defaults |
| **Git** | Homebrew / Xcode CLT | apt | Version control |
| **SSH Key** | ssh-keygen | ssh-keygen | Auth for GitHub, servers, etc. |
| **Homebrew** | Official installer | — | macOS package manager |
| **NVM + Node.js LTS** | nvm | nvm | JavaScript runtime + version manager |
| **PNPM** | Corepack | Corepack | Fast, disk-efficient package manager |
| **Deno** | Official installer | Official installer | TypeScript runtime |
| **Rust** | rustup | rustup | Systems programming |
| **Zoxide** | Homebrew | Official installer | Smart `z` directory jumper |
| **Vercel CLI** | npm | npm | Deploy and manage Vercel projects |
| **Supabase CLI** | Homebrew | GitHub releases (.deb) | Manage Supabase projects |
| **GitHub CLI** | Homebrew | Official apt repo | PRs, issues, repos from the terminal |
| **Stripe CLI** | Homebrew | Official apt repo | Test webhooks, manage Stripe |
| **PostgreSQL CLI** | Homebrew (libpq) | apt | `psql`, `pg_dump`, etc. without a full server |
| **AWS CLI v2** | Official pkg | Official zip (x86_64/arm64) | Manage AWS services |
| **Claude Code CLI** | Official installer | Official installer | AI-assisted development |
| **VS Code** | Homebrew cask | apt repo / WSL guidance | Code editor + Claude Code extension |
| **Xcode CLT** | xcode-select | — | macOS build tools (git, make, clang) |

The script also handles **service logins** (Vercel, Supabase, GitHub, AWS, Stripe) — already-authenticated services are automatically skipped.

### WSL-Specific

On WSL, the installer automatically:
- Detects the WSL environment and shows WSL-specific guidance
- Installs **wslu** so CLI login flows can open your Windows browser
- Configures **ssh-agent auto-start** so keys persist across sessions
- Sets up **zsh** as default shell with a `.zshrc` that sources NVM, Cargo, and Deno
- Guides you to install VS Code on Windows with the WSL extension (the recommended workflow)

## Windows Bootstrap

Windows users need WSL (Windows Subsystem for Linux) to use the dev tools installer. The `bootstrap-windows.ps1` script handles this automatically:

1. Enables WSL and sets WSL 2 as default
2. Installs Ubuntu
3. Runs the dev-tools installer inside WSL

After bootstrapping, do all development work inside WSL — open Windows Terminal → Ubuntu, or type `wsl` in PowerShell.

## Re-run Behavior

The script is designed to be run as many times as you want:

- Tools already installed show a green checkmark and are skipped
- Service logins check auth status before prompting
- NVM/Node won't re-install if already present
- SSH key is displayed on every run for easy copying
- The Windows bootstrap skips WSL/Ubuntu setup if already present
