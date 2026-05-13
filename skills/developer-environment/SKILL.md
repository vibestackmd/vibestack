---
name: developer-environment
description: Reference map of the user's local development environment, installed languages, runtimes, version managers, databases, cloud CLIs, and tools on this machine. READ this file BEFORE telling the user a tool is unavailable, BEFORE asking which deploy target / cloud / DB to use, and BEFORE proposing to install something. If a CLI is listed as installed, assume it works. If listed as not installed, don't suggest commands that depend on it without flagging the install step. If the file shows "(not yet populated)" below, run the discovery steps to fill it in on first use.
user-invocable: false
---

# Local developer environment (last verified: not yet populated)

This file is a reference map of the developer's machine, what's installed, what versions, what's running. It auto-loads as context so Claude can answer "do you have X?" without trial-and-error.

**Scope note.** This skill describes the *machine*, not the project. It's equally useful at user level (`~/.claude/skills/developer-environment/`) and project level (`.claude/skills/developer-environment/`). For cross-project use, copy it to user level after populating.

---

## Host

(not yet populated)

## Languages & runtimes

| Tool | Version | Manager |
|---|---|---|
| _populate from discovery_ | | |

## Package managers

(not yet populated)

## Databases / data

(not yet populated)

## Cloud / deploy CLIs

(not yet populated)

## Containers / infra

(not yet populated)

## Other notable CLIs

(not yet populated)

---

## First-time discovery (populate this file)

If the sections above show "(not yet populated)", run these probes and fill in the tables. Keep entries terse, a name and version per line is enough. Mark missing-but-commonly-asked-for tools as `❌ Not installed`.

```bash
# Host
sw_vers | head -3; uname -m; echo "Shell: $SHELL"; brew --version 2>/dev/null | head -1

# Languages, only list what's actually installed
for cmd in node deno bun python3 ruby go rustc java swift php elixir erlang lua zig; do
  command -v $cmd >/dev/null && echo "$cmd: $($cmd --version 2>&1 | head -1)"
done
go version 2>/dev/null  # `go --version` doesn't work

# Version managers
for vm in nvm fnm volta rbenv rvm pyenv asdf mise rustup goenv jenv sdkman; do
  command -v $vm >/dev/null && echo "$vm: installed"
done
[ -d "$HOME/.nvm" ] && echo "nvm dir present"
[ -d "$HOME/.rustup" ] && echo "rustup dir present"

# Package managers
for cmd in brew npm pnpm yarn bun pip3 pipx poetry uv conda gem cargo composer; do
  command -v $cmd >/dev/null && echo "$cmd: $($cmd --version 2>&1 | head -1)"
done
npm ls -g --depth=0 2>/dev/null | head -20

# Databases
for cmd in psql mysql sqlite3 redis-cli mongosh duckdb clickhouse-client; do
  command -v $cmd >/dev/null && echo "$cmd: $($cmd --version 2>&1 | head -1)"
done
brew services list 2>/dev/null  # macOS: shows running DBs

# Cloud / deploy CLIs
for cmd in gh vercel netlify aws gcloud az heroku flyctl railway supabase wrangler firebase doctl render terraform pulumi; do
  command -v $cmd >/dev/null && echo "$cmd: $($cmd --version 2>&1 | head -1)"
done

# Containers / infra
for cmd in docker podman colima kubectl helm kind minikube k3d; do
  command -v $cmd >/dev/null && echo "$cmd: $($cmd --version 2>&1 | head -1)"
done

# Other notable CLIs
for cmd in jq yq fzf rg fd bat eza httpie tmux ngrok stripe ollama direnv mkcert; do
  command -v $cmd >/dev/null && echo "$cmd: $($cmd --version 2>&1 | head -1)"
done
```

After populating, replace "not yet populated" in the header with today's date in `YYYY-MM-DD` format.

**Important, don't include in this file:**
- Authentication identities (account IDs, emails, GitHub handles, AWS account numbers). They're sensitive and they drift.
- Project-specific tools (cargo bins for one Rust project, language toolchains for one stack). This file is the *machine map*, not a project inventory.
- Anything that lives in a `.env`, project `package.json`, or repo config, that's project-scoped.

---

## Keeping this file fresh

Once populated, this file should stay accurate. Update it opportunistically when you observe a relevant change in the current session, you don't need to ask permission for narrow edits.

**Update when you see:**
- A successful machine-wide install or uninstall: `brew install/uninstall`, `npm i -g`, `pnpm add -g`, `cargo install`, `pipx install`, `gem install`, `go install`, downloaded CLI binaries placed on `$PATH`.
- A version bump of a tool already listed (e.g. Node 22.14 → 22.15 after `nvm install`).
- A new database/service started or stopped via `brew services` (or systemd on Linux).
- A new language toolchain added (rustup, new JDK, new Xcode).

**Do NOT update for:**
- `npx`, `pipx run`, `bunx`, or any one-shot invocation.
- Project-local installs (`npm i` without `-g`, `cargo add` inside a crate, `pip install` inside a venv).
- Transient installs that get reverted in the same session.
- Auth state changes (we deliberately don't track identities here).

**How to edit:**
- Make the smallest possible change. Move one line between installed / ❌ not installed, or bump one version cell. Don't re-survey the whole machine.
- Bump the "last verified" date at the top whenever you edit.
- If a section is materially out of date, say so to the user and ask before doing a fuller refresh.

**Full refresh** (only when the user explicitly asks "refresh the dev env skill"): re-run the discovery commands above, mirror the existing structure, and prune sections back to ~10 items max.
