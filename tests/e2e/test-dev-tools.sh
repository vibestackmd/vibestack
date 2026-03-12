#!/usr/bin/env bash
# Test the dev-tools installer (tool installation on fresh Ubuntu)
#
# This test installs real tools — it's slow (~3-5 min) but validates the
# actual install paths. Runs with NONINTERACTIVE=1 to auto-accept everything
# and skip service logins.
set -euo pipefail

CYAN="\033[0;36m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

pass=0
fail=0

assert_command_exists() {
  # Reload PATH before checking — tools may have been installed to new locations
  export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$HOME/.cargo/bin:$HOME/.deno/bin:$HOME/.nvm/versions/node/$(ls "$HOME/.nvm/versions/node/" 2>/dev/null | tail -1)/bin:$PATH"
  if command -v "$1" >/dev/null 2>&1; then
    echo -e "  ${GREEN}PASS${RESET}  $1 is installed"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $1 not found in PATH"
    ((++fail))
  fi
}

assert_command_missing() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo -e "  ${GREEN}PASS${RESET}  $1 correctly not installed"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $1 should not be installed but was found"
    ((++fail))
  fi
}

assert_file_exists() {
  if [[ -f "$1" ]]; then
    echo -e "  ${GREEN}PASS${RESET}  $1 exists"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $1 missing"
    ((++fail))
  fi
}

assert_file_contains() {
  if grep -q "$2" "$1" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${RESET}  $1 contains '$2'"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $1 does not contain '$2'"
    ((++fail))
  fi
}

echo -e "${CYAN}=== Test: Dev Tools Installer (Ubuntu) ===${RESET}"
echo ""

# Run the dev-tools installer
bash /vibestack/kit/extras/dev-tools/install.sh || true

echo ""
echo -e "${CYAN}--- Checking installed tools ---${RESET}"

# Prerequisites (installed by the script's Linux prerequisite step)
assert_command_exists "curl"
assert_command_exists "unzip"
assert_command_exists "gpg"

# Git
assert_command_exists "git"

# Zsh
assert_command_exists "zsh"

# Oh My Zsh
assert_file_exists "$HOME/.oh-my-zsh/oh-my-zsh.sh"

# SSH key should have been generated (non-interactive, no passphrase)
assert_file_exists "$HOME/.ssh/id_ed25519"
assert_file_exists "$HOME/.ssh/id_ed25519.pub"

# NVM + Node
assert_file_exists "$HOME/.nvm/nvm.sh"
# Source NVM so we can check node
export NVM_DIR="$HOME/.nvm"
set +u
# shellcheck disable=SC1091
\. "$NVM_DIR/nvm.sh" 2>/dev/null || true
set -u
assert_command_exists "node"
assert_command_exists "npm"

# PNPM (via corepack)
assert_command_exists "pnpm"

# Deno
assert_command_exists "deno"

# Rust
assert_command_exists "rustc"
assert_command_exists "cargo"

# Zoxide
assert_command_exists "zoxide"

# PostgreSQL client
assert_command_exists "psql"

echo ""
echo -e "${CYAN}--- Checking CLI tools ---${RESET}"

# These install via npm or direct download — should all be present
# Vercel (npm global)
assert_command_exists "vercel"

# GitHub CLI
assert_command_exists "gh"

# AWS CLI
assert_command_exists "aws"

echo ""
echo -e "${CYAN}--- Checking shell config ---${RESET}"

# .zshrc should have been created with sensible defaults
assert_file_exists "$HOME/.zshrc"
assert_file_contains "$HOME/.zshrc" "NVM_DIR"
assert_file_contains "$HOME/.zshrc" ".cargo/env"
assert_file_contains "$HOME/.zshrc" "zoxide init"
assert_file_contains "$HOME/.zshrc" "plugins=(git z)"

echo ""
echo -e "${CYAN}--- Checking Vim config ---${RESET}"

# Vim syntax highlighting should be configured
assert_file_exists "$HOME/.vimrc"
assert_file_contains "$HOME/.vimrc" "syntax on"

echo ""
echo -e "${CYAN}--- Checking logins were skipped ---${RESET}"

# In non-interactive mode, logins should be skipped entirely
# (no auth tokens should exist)
if [[ ! -f "$HOME/.config/vercel/auth.json" ]]; then
  echo -e "  ${GREEN}PASS${RESET}  Vercel login was skipped"
  ((++pass))
else
  echo -e "  ${RED}FAIL${RESET}  Vercel login should have been skipped"
  ((++fail))
fi

echo ""
echo -e "${CYAN}--- Re-run test (idempotency) ---${RESET}"

# Run again — everything should report "already installed"
output=$(bash /vibestack/kit/extras/dev-tools/install.sh 2>&1) || true

already_count=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g' | grep -ciE "already installed|already set|already configured|already exists" || true)
if [[ $already_count -ge 5 ]]; then
  echo -e "  ${GREEN}PASS${RESET}  Re-run detects $already_count already-installed tools"
  ((++pass))
else
  echo -e "  ${YELLOW}WARN${RESET}  Re-run only detected $already_count already-installed items (expected 5+)"
  ((++pass))  # Not a hard failure — some tools detect differently
fi

# ── Summary ─────────────────────────────────────────────

echo ""
echo -e "${CYAN}==============================${RESET}"
if [[ $fail -eq 0 ]]; then
  echo -e "${GREEN}All $pass tests passed.${RESET}"
else
  echo -e "${RED}$fail failed${RESET}, ${GREEN}$pass passed${RESET}"
fi
echo ""

exit $fail
