#!/usr/bin/env bash
# VibeStack Installer (v2 — user-level)
# Installs VibeStack skills, hooks, and settings into the user's ~/.claude/
# directory so they apply across every project on this machine.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/install.sh | bash

set -euo pipefail

REPO="${VIBESTACK_REPO:-https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit}"
USER_DIR="$HOME/.claude"

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
DIM="\033[2m"
RESET="\033[0m"

echo -e "${CYAN}▓▒░ VibeStack Installer${RESET}"
echo -e "${DIM}Installing to $USER_DIR${RESET}"
echo ""

# Skills shipped to ~/.claude/skills/<name>/SKILL.md
SKILLS=(
  "vibestack"
  "todo"
  "squad"
  "docs"
  "bosskey"
  "ideate"
  "cli-first"
  "developer-environment"
  "lsp"
)

# Extra files shipped alongside specific skills (path relative to ~/.claude/)
SKILL_EXTRAS=(
  "skills/vibestack/templates/CLAUDE.md"
  "skills/vibestack/templates/Makefile"
)

# Hooks shipped to ~/.claude/hooks/<name>.sh
HOOKS=(
  "notify-done.sh"
  "statusline.sh"
)

# settings.json gets deep-merged into the user's existing file
SETTINGS_PATH=".claude/settings.json"

installed=0
skipped=0
merged=0
updated=0

ask() {
  if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
    echo "$1 [y/N] y (non-interactive)"
    return 0
  fi
  local choice
  read -rp "$1 [y/N] " choice < /dev/tty
  [[ "$choice" =~ ^[Yy]$ ]]
}

ask_yes() {
  if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
    echo "$1 [Y/n] y (non-interactive)"
    return 0
  fi
  local choice
  read -rp "$1 [Y/n] " choice < /dev/tty
  [[ ! "$choice" =~ ^[Nn]$ ]]
}

# install_managed: fetch a file from the kit and place it at a target path,
# prompting the user if the file already exists and differs from upstream.
install_managed() {
  local src="$1" dest="$2"
  local dir
  dir=$(dirname "$dest")

  if [[ -f "$dest" ]]; then
    local tmp
    tmp=$(mktemp)
    if curl -fsSL "$REPO/$src" -o "$tmp" 2>/dev/null; then
      if diff -q "$dest" "$tmp" >/dev/null 2>&1; then
        echo -e "  ${GREEN}ok${RESET}    ${dest/#$HOME/~} (up to date)"
        rm -f "$tmp"
        return
      fi
      echo -e "  ${YELLOW}update${RESET} ${dest/#$HOME/~} has upstream changes"
      if ask_yes "         Overwrite with latest version?"; then
        mv "$tmp" "$dest"
        echo -e "  ${GREEN}update${RESET} ${dest/#$HOME/~}"
        ((++updated))
      else
        echo -e "  ${YELLOW}skip${RESET}  ${dest/#$HOME/~} (kept existing)"
        rm -f "$tmp"
        ((++skipped))
      fi
    else
      echo -e "  ${YELLOW}fail${RESET}  ${dest/#$HOME/~}"
      rm -f "$tmp"
    fi
    return
  fi

  mkdir -p "$dir"
  if curl -fsSL "$REPO/$src" -o "$dest"; then
    echo -e "  ${GREEN}add${RESET}   ${dest/#$HOME/~}"
    ((++installed))
  else
    echo -e "  ${YELLOW}fail${RESET}  ${dest/#$HOME/~}"
  fi
}

# Install skills
for skill in "${SKILLS[@]}"; do
  install_managed ".claude/skills/$skill/SKILL.md" "$USER_DIR/skills/$skill/SKILL.md"
done

# Install skill extras (templates, etc.)
for extra in "${SKILL_EXTRAS[@]}"; do
  install_managed ".claude/$extra" "$USER_DIR/$extra"
done

# Install hooks
for hook in "${HOOKS[@]}"; do
  install_managed ".claude/hooks/$hook" "$USER_DIR/hooks/$hook"
done
chmod +x "$USER_DIR/hooks/notify-done.sh" "$USER_DIR/hooks/statusline.sh" 2>/dev/null || true

# Deep-merge settings.json. Existing user values win; new keys are added.
mkdir -p "$USER_DIR"
tmp=$(mktemp)
if ! curl -fsSL "$REPO/$SETTINGS_PATH" -o "$tmp"; then
  echo -e "  ${YELLOW}fail${RESET}  ${USER_DIR/#$HOME/~}/settings.json"
  rm -f "$tmp"
elif [[ ! -f "$USER_DIR/settings.json" ]]; then
  mv "$tmp" "$USER_DIR/settings.json"
  echo -e "  ${GREEN}add${RESET}   ~/.claude/settings.json"
  ((++installed))
else
  merged_json=$(/usr/bin/python3 -c "
import json, sys

def deep_merge(base, incoming):
    for key, val in incoming.items():
        if key not in base:
            base[key] = val
        elif isinstance(base[key], dict) and isinstance(val, dict):
            deep_merge(base[key], val)
        elif isinstance(base[key], list) and isinstance(val, list):
            for item in val:
                if item not in base[key]:
                    base[key].append(item)
        # else: keep the existing base value
    return base

with open(sys.argv[1]) as f:
    existing = json.load(f)
with open(sys.argv[2]) as f:
    incoming = json.load(f)

print(json.dumps(deep_merge(existing, incoming), indent=2))
" "$USER_DIR/settings.json" "$tmp" 2>/dev/null)

  if [[ -n "$merged_json" ]]; then
    echo "$merged_json" > "$USER_DIR/settings.json"
    echo -e "  ${GREEN}merge${RESET} ~/.claude/settings.json"
    ((++merged))
  else
    echo -e "  ${YELLOW}fail${RESET}  ~/.claude/settings.json (merge failed, kept existing)"
  fi
  rm -f "$tmp"
fi

echo ""
echo -e "${GREEN}Done!${RESET} Added $installed, updated $updated, merged $merged, skipped $skipped."

# ── Optional: Dev Tools Installer ───────────────────────

DEV_TOOLS_REPO="https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/dev-tools"

is_windows_native=false
is_wsl=false
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) is_windows_native=true ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      is_wsl=true
    fi
    ;;
esac

echo ""
echo -e "${CYAN}── Optional: Dev Environment Setup ──${RESET}"
echo ""
echo "VibeStack ships an opinionated dev-tools installer that sets up your entire"
echo "development environment in one pass. It's designed so every developer on"
echo "a team has the same tools available — and so Claude has CLI access to the"
echo "most popular platforms."
echo ""
echo "  What it installs (each tool is optional — you pick during setup):"
echo ""
echo "    Languages & Runtimes   Node.js (via NVM), PNPM, Deno, Rust"
echo "    Cloud & Deploy         AWS CLI, Vercel CLI, Supabase CLI"
echo "    Code & Git             GitHub CLI, Git, SSH key, VS Code"
echo "    Payments               Stripe CLI"
echo "    Database               PostgreSQL CLI (psql)"
echo "    AI                     Claude Code CLI + claw alias"
echo "    Utilities              Zsh (Linux)"
echo ""
echo -e "  ${YELLOW}This is opinionated.${RESET} It installs real tools globally and offers to log"
echo "  you into services. Great for onboarding new devs or standardizing a team."
echo "  Every tool prompts individually — nothing is installed without asking."
echo ""

if [[ "${SKIP_DEVTOOLS:-0}" == "1" ]]; then
  echo -e "  ${DIM}Skipped (SKIP_DEVTOOLS=1).${RESET}"
  echo ""
elif $is_windows_native; then
  echo -e "  ${YELLOW}Detected: Windows (native shell)${RESET}"
  echo ""
  echo "  The dev-tools installer runs inside WSL (Windows Subsystem for Linux)."
  echo "  VibeStack includes a PowerShell bootstrap that sets up WSL + Ubuntu"
  echo "  and then runs the dev-tools installer inside it automatically."
  echo ""
  echo "  To set it up, open PowerShell as Administrator and run:"
  echo ""
  echo -e "    ${CYAN}Invoke-RestMethod \"${DEV_TOOLS_REPO}/bootstrap-windows.ps1\" | Set-Content \"\$env:TEMP\\bootstrap-windows.ps1\"; powershell -ExecutionPolicy Bypass -File \"\$env:TEMP\\bootstrap-windows.ps1\"${RESET}"
  echo ""
  echo "  This will:"
  echo "    1. Enable WSL 2 (may require a restart)"
  echo "    2. Install Ubuntu"
  echo "    3. Run the dev-tools installer inside Ubuntu"
  echo ""
else
  if $is_wsl; then
    echo -e "  ${DIM}Detected: WSL — the installer handles WSL-specific setup automatically.${RESET}"
    echo ""
  fi
  if ! ask "  Run the dev-tools installer now?"; then
    echo ""
    echo "  No problem. You can run it anytime:"
    echo ""
    echo -e "    ${CYAN}curl -fsSL ${DEV_TOOLS_REPO}/install.sh | bash${RESET}"
    echo ""
  else
    echo ""
    curl -fsSL "${DEV_TOOLS_REPO}/install.sh" | NONINTERACTIVE="${NONINTERACTIVE:-0}" bash
  fi
fi

echo ""
echo "Next steps:"
echo "  • Open Claude Code in any project and run /vibestack to scaffold it"
echo "  • All VibeStack skills are now available globally — no per-project install needed"
echo ""
