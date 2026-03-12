#!/usr/bin/env bash
# VibeStack Installer
# Adds VibeStack convention files to the current project.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/install.sh | bash

set -euo pipefail

REPO="https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit"

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
DIM="\033[2m"
RESET="\033[0m"

echo -e "${CYAN}🧱 VibeStack Installer${RESET}"
echo ""

# Project-specific files — never overwrite, these contain user content
PROJECT_FILES=(
  "CLAUDE.md"
  "TODO.md"
  "ops.sh"
  "docs/README.md"
  "docs/SUMMARY.md"
  "docs/index.md"
  "docs/skills-and-commands.md"
)

# VibeStack-managed files — prompt to overwrite on re-runs so upstream
# fixes (hook paths, skill updates) can be picked up
MANAGED_FILES=(
  ".claude/skills/vibestack/SKILL.md"
  ".claude/skills/cli-first/SKILL.md"
  ".claude/skills/docs/SKILL.md"
  ".claude/skills/squad/SKILL.md"
  ".claude/skills/todo/SKILL.md"
  ".claude/hooks/notify-done.sh"
  ".claude/hooks/statusline.sh"
)

# Files to deep-merge instead of skip/overwrite
MERGE_FILES=(
  ".claude/settings.json"
)

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

# Install project-specific files (skip if they exist)
for file in "${PROJECT_FILES[@]}"; do
  dir=$(dirname "$file")

  if [[ -f "$file" ]]; then
    echo -e "  ${YELLOW}skip${RESET}  $file (already exists)"
    ((++skipped))
    continue
  fi

  mkdir -p "$dir"
  if curl -fsSL "$REPO/$file" -o "$file"; then
    echo -e "  ${GREEN}add${RESET}   $file"
    ((++installed))
  else
    echo -e "  ${YELLOW}fail${RESET}  $file"
  fi
done

# Install managed files (prompt to update if they exist)
for file in "${MANAGED_FILES[@]}"; do
  dir=$(dirname "$file")

  if [[ -f "$file" ]]; then
    # Download to temp and check if it actually differs
    tmp=$(mktemp)
    if curl -fsSL "$REPO/$file" -o "$tmp" 2>/dev/null; then
      if diff -q "$file" "$tmp" >/dev/null 2>&1; then
        echo -e "  ${GREEN}ok${RESET}    $file (up to date)"
        rm -f "$tmp"
        continue
      fi
      echo -e "  ${YELLOW}update${RESET} $file has upstream changes"
      if ask_yes "         Overwrite with latest version?"; then
        mv "$tmp" "$file"
        echo -e "  ${GREEN}update${RESET} $file"
        ((++updated))
      else
        echo -e "  ${YELLOW}skip${RESET}  $file (kept existing)"
        rm -f "$tmp"
        ((++skipped))
      fi
    else
      echo -e "  ${YELLOW}fail${RESET}  $file"
      rm -f "$tmp"
    fi
    continue
  fi

  mkdir -p "$dir"
  if curl -fsSL "$REPO/$file" -o "$file"; then
    echo -e "  ${GREEN}add${RESET}   $file"
    ((++installed))
  else
    echo -e "  ${YELLOW}fail${RESET}  $file"
  fi
done

# Deep-merge JSON files: new keys are added, existing keys are preserved
for file in "${MERGE_FILES[@]}"; do
  dir=$(dirname "$file")
  mkdir -p "$dir"

  # Download the incoming template to a temp file
  tmp=$(mktemp)
  if ! curl -fsSL "$REPO/$file" -o "$tmp"; then
    echo -e "  ${YELLOW}fail${RESET}  $file"
    rm -f "$tmp"
    continue
  fi

  if [[ ! -f "$file" ]]; then
    # No existing file — just use the template
    mv "$tmp" "$file"
    echo -e "  ${GREEN}add${RESET}   $file"
    ((++installed))
  else
    # Deep-merge: existing values win, new keys are added
    merged_json=$(/usr/bin/python3 -c "
import json, sys

def deep_merge(base, incoming):
    \"\"\"Merge incoming into base. base values take priority.
    For arrays, incoming items are appended if not already present.\"\"\"
    for key, val in incoming.items():
        if key not in base:
            base[key] = val
        elif isinstance(base[key], dict) and isinstance(val, dict):
            deep_merge(base[key], val)
        elif isinstance(base[key], list) and isinstance(val, list):
            # Append incoming list items that aren't already present
            for item in val:
                if item not in base[key]:
                    base[key].append(item)
        # else: keep the existing base value
    return base

with open(sys.argv[1]) as f:
    existing = json.load(f)
with open(sys.argv[2]) as f:
    incoming = json.load(f)

result = deep_merge(existing, incoming)
print(json.dumps(result, indent=2))
" "$file" "$tmp" 2>/dev/null)

    if [[ -n "$merged_json" ]]; then
      echo "$merged_json" > "$file"
      echo -e "  ${GREEN}merge${RESET} $file"
      ((++merged))
    else
      echo -e "  ${YELLOW}fail${RESET}  $file (merge failed, kept existing)"
    fi
    rm -f "$tmp"
  fi
done

# Make scripts executable
[[ -f "ops.sh" ]] && chmod +x ops.sh
[[ -f ".claude/hooks/notify-done.sh" ]] && chmod +x .claude/hooks/notify-done.sh
[[ -f ".claude/hooks/statusline.sh" ]] && chmod +x .claude/hooks/statusline.sh

echo ""
echo -e "${GREEN}Done!${RESET} Added $installed, updated $updated, merged $merged, skipped $skipped."

# ── Optional: Dev Tools Installer ───────────────────────

DEV_TOOLS_REPO="https://raw.githubusercontent.com/tylerthebuildor/vibestack/main/kit/extras/dev-tools"

# Detect platform
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
echo "    Utilities              Zoxide (smart cd), Zsh (Linux)"
echo ""
echo -e "  ${YELLOW}This is opinionated.${RESET} It installs real tools globally and offers to log"
echo "  you into services. Great for onboarding new devs or standardizing a team."
echo "  Every tool prompts individually — nothing is installed without asking."
echo ""

if [[ "${SKIP_DEVTOOLS:-0}" == "1" ]]; then
  echo -e "  ${DIM}Skipped (SKIP_DEVTOOLS=1).${RESET}"
  echo ""
elif $is_windows_native; then
  # Running in Git Bash / MSYS2 on Windows — can't run the bash installer directly
  echo -e "  ${YELLOW}Detected: Windows (native shell)${RESET}"
  echo ""
  echo "  The dev-tools installer runs inside WSL (Windows Subsystem for Linux)."
  echo "  VibeStack includes a PowerShell bootstrap that sets up WSL + Ubuntu"
  echo "  and then runs the dev-tools installer inside it automatically."
  echo ""
  echo "  To set it up, open PowerShell as Administrator and run:"
  echo ""
  echo -e "    ${CYAN}Invoke-WebRequest -Uri \"${DEV_TOOLS_REPO}/bootstrap-windows.ps1\" -OutFile \"\$env:TEMP\\bootstrap-windows.ps1\"${RESET}"
  echo -e "    ${CYAN}powershell -ExecutionPolicy Bypass -File \"\$env:TEMP\\bootstrap-windows.ps1\"${RESET}"
  echo ""
  echo "  This will:"
  echo "    1. Enable WSL 2 (may require a restart)"
  echo "    2. Install Ubuntu"
  echo "    3. Run the dev-tools installer inside Ubuntu"
  echo ""
else
  # macOS, Linux, or WSL — can run the bash installer directly
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
echo "  1. Run /vibestack in Claude Code to auto-configure everything for your project"
echo "  2. Review the generated CLAUDE.md, ops.sh, docs/, and TODO.md"
echo ""
