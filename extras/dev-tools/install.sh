#!/usr/bin/env bash
#
# VibeStack Dev Tools Installer (cross-platform: macOS + Linux/WSL Ubuntu)
#
# Sets up common developer CLIs. Safe to re-run — skips installed tools/logins.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/kit/extras/dev-tools/install.sh | bash
#   or ./install.sh (if cloned)

set -uo pipefail
# NOTE: We intentionally do NOT use `set -e` because sourcing shell configs
# (e.g. .zshrc) can produce non-zero exits that would kill the script.

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"

DIVIDER="────────────────────────────────────────────────────────"

echo ""
echo -e "${CYAN}${BOLD}VibeStack Dev Tools Installer${RESET}"
echo "macOS or Linux/WSL — common dev CLIs"
echo "Each tool is optional — answer the prompts to pick what you need."
echo "Safe to re-run: already-installed tools and active logins are skipped."
echo ""

# ── Detect OS ────────────────────────────────────────────

WSL=false
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "linux-musl"* ]]; then
  OS="linux"
  if grep -qi microsoft /proc/version 2>/dev/null; then
    WSL=true
  fi
else
  echo -e "${RED}Unsupported OS: $OSTYPE${RESET}"
  exit 1
fi

if $WSL; then
  echo -e "${CYAN}Detected: Linux (WSL)${RESET}"
else
  echo -e "${CYAN}Detected: $OS${RESET}"
fi
echo ""

# ── Helpers ──────────────────────────────────────────────

ask() {
  local prompt="$1"
  local default="${2:-y}"
  if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
    # In non-interactive mode, accept everything except logins
    echo "$prompt [auto] y (non-interactive)"
    return 0
  fi
  local choice
  if [[ "$default" == "y" ]]; then
    read -rp "$prompt [Y/n] " choice < /dev/tty
    choice=${choice:-y}
  else
    read -rp "$prompt [y/N] " choice < /dev/tty
    choice=${choice:-n}
  fi
  [[ "$choice" =~ ^[Yy]$ ]]
}

reload_config() {
  # Re-add common paths so newly-installed tools are found immediately.
  # Avoids sourcing .zshrc/.bashrc which can have side effects or exit codes.
  export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$HOME/.cargo/bin:$HOME/.deno/bin:$PATH"
  # nvm.sh has unbound variables — temporarily disable -u while sourcing it.
  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    set +u
    \. "$HOME/.nvm/nvm.sh" --no-use 2>/dev/null || true
    set -u
  fi
  if [[ "$OS" == "macos" ]]; then
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)" || true
    elif [ -x /usr/local/bin/brew ]; then
      eval "$(/usr/local/bin/brew shellenv 2>/dev/null)" || true
    fi
  fi
}

installed=()
skipped=()

track() {
  if [[ "$2" == "installed" ]]; then
    installed+=("$1")
  else
    skipped+=("$1")
  fi
}

ok() {
  echo -e "  ${GREEN}✓${RESET} $1"
}

# macOS: 15 (Homebrew + Xcode CLT + Oh My Zsh, no Prerequisites/Zsh)
# Linux: 15 (Prerequisites + Zsh + Oh My Zsh, no Homebrew/Xcode CLT)
total=15
step=1

section() {
  echo ""
  echo -e "${CYAN}${DIVIDER}${RESET}"
  echo -e "${CYAN}${BOLD} $step/$total  $1${RESET}"
  echo -e "${CYAN}${DIVIDER}${RESET}"
  echo ""
  ((step++))
}

# ── Linux/WSL Prerequisites ──────────────────────────────
# Ensure essential tools are available before the rest of the script runs.

if [[ "$OS" == "linux" ]]; then
  section "Linux Prerequisites"

  # Fix malformed apt sources left by a previous run of this script.
  # The old GitHub CLI install used eval which mangled the arch variable,
  # producing a broken sources.list entry that blocks all apt-get commands.
  if [[ -f /etc/apt/sources.list.d/github-cli.list ]] && grep -q '\[option\]\|\\$\|dpkg --print-architecture' /etc/apt/sources.list.d/github-cli.list 2>/dev/null; then
    echo -e "  ${YELLOW}Found malformed /etc/apt/sources.list.d/github-cli.list from a previous run.${RESET}"
    echo "  Removing it so apt-get works correctly..."
    sudo rm -f /etc/apt/sources.list.d/github-cli.list
    ok "Removed malformed github-cli.list."
    echo ""
  fi

  echo "  Updating package lists and installing essential tools (curl, unzip, gpg, build-essential)..."
  echo ""
  sudo apt-get update -y
  sudo apt-get install -y curl unzip gpg build-essential
  ok "Prerequisites installed."

  # WSL: install wslu so browser-based logins (Vercel, GitHub, Stripe) can
  # open URLs in the Windows host browser via wslview.
  if $WSL; then
    if ! command -v wslview >/dev/null 2>&1; then
      echo ""
      echo "  wslu provides wslview, which lets CLI tools open your Windows browser"
      echo "  for login flows (GitHub, Vercel, Stripe, etc.)."
      echo ""
      if ask "  Install wslu (recommended for WSL)?"; then
        sudo apt-get install -y wslu
        track "wslu" "installed"
      else
        echo -e "  ${YELLOW}Skipped — some login commands may not open a browser automatically.${RESET}"
        track "wslu" "skipped"
      fi
    else
      ok "wslu already installed."
    fi
  fi
fi

# ── Zsh (Linux/WSL) ─────────────────────────────────────

if [[ "$OS" == "linux" ]]; then
  section "Zsh"
  if command -v zsh >/dev/null 2>&1; then
    ok "Already installed ($(zsh --version | cut -d' ' -f1-2))."
  else
    if ask "  Install Zsh?"; then
      sudo apt-get install -y zsh
      track "Zsh" "installed"
    else
      track "Zsh" "skipped"
    fi
  fi

  # Offer to set zsh as default shell
  if command -v zsh >/dev/null 2>&1; then
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$current_shell" == */zsh ]]; then
      ok "Already set as default shell."
    elif ask "  Set Zsh as your default shell?"; then
      if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
        sudo chsh -s "$(which zsh)" "$USER" 2>/dev/null || true
      else
        chsh -s "$(which zsh)" < /dev/tty
      fi
      ok "Zsh set as default (takes effect on next terminal session)."
    fi

  fi
fi

# ── 1. Git ───────────────────────────────────────────────

section "Git"
if command -v git >/dev/null 2>&1; then
  ok "Already installed ($(git --version | sed 's/git version //'))."
else
  echo "  Git is not installed."
  if [[ "$OS" == "macos" ]]; then
    if command -v brew >/dev/null 2>&1; then
      if ask "  Install Git via Homebrew?"; then
        brew install git
        track "Git" "installed"
      else
        track "Git" "skipped"
      fi
    else
      echo -e "  ${DIM}Will be installed with Xcode Command Line Tools (last step).${RESET}"
    fi
  else
    if ask "  Install Git via apt?"; then
      sudo apt-get update && sudo apt-get install -y git
      track "Git" "installed"
    else
      track "Git" "skipped"
    fi
  fi
fi

# ── Oh My Zsh ──────────────────────────────────────────
# Requires git (installed above) to clone the repository.

section "Oh My Zsh"
if ! command -v zsh >/dev/null 2>&1; then
  echo -e "  ${DIM}Zsh not installed — skipping.${RESET}"
elif ! command -v git >/dev/null 2>&1; then
  echo -e "  ${DIM}Git not installed — skipping (Oh My Zsh requires git).${RESET}"
else
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "Already installed."
  else
    echo "  Oh My Zsh adds themes, plugins, and sensible defaults to Zsh."
    echo ""
    if ask "  Install Oh My Zsh?"; then
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
      track "Oh My Zsh" "installed"
    else
      track "Oh My Zsh" "skipped"
    fi
  fi

  # Set plugins=(git z) if Oh My Zsh is installed
  if [[ -d "$HOME/.oh-my-zsh" ]] && [[ -f "$HOME/.zshrc" ]]; then
    if grep -q '^plugins=(' "$HOME/.zshrc"; then
      current_plugins=$(grep '^plugins=(' "$HOME/.zshrc")
      if [[ "$current_plugins" == "plugins=(git z)" ]]; then
        ok "plugins=(git z) already configured."
      else
        if [[ "$OS" == "macos" ]]; then
          sed -i '' 's/^plugins=(.*/plugins=(git z)/' "$HOME/.zshrc"
        else
          sed -i 's/^plugins=(.*/plugins=(git z)/' "$HOME/.zshrc"
        fi
        ok "Set plugins=(git z) in ~/.zshrc."
      fi
    fi
  fi
fi

# Ensure ~/.zshrc exists with sensible defaults (when Oh My Zsh was skipped)
if command -v zsh >/dev/null 2>&1 && [[ ! -f "$HOME/.zshrc" ]]; then
  cat > "$HOME/.zshrc" << 'ZSHRC'
# ~/.zshrc

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Cargo (Rust)
[ -f "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"

# Deno
export DENO_INSTALL="$HOME/.deno"
[ -d "$DENO_INSTALL" ] && export PATH="$DENO_INSTALL/bin:$PATH"

# SSH agent (WSL) — auto-start so keys persist across sessions
if grep -qi microsoft /proc/version 2>/dev/null; then
  if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    find ~/.ssh -name "id_*" ! -name "*.pub" -exec ssh-add {} \; 2>/dev/null
  fi
fi
ZSHRC
  ok "Created ~/.zshrc with sensible defaults."
fi

# Ensure essential entries exist in .zshrc (whether OMZ-managed or basic)
if [[ -f "$HOME/.zshrc" ]]; then
  if ! grep -qF '.local/bin' "$HOME/.zshrc"; then
    echo '' >> "$HOME/.zshrc"
    echo '# Local bin (added by vibestack installer)' >> "$HOME/.zshrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    ok "Added ~/.local/bin to PATH in ~/.zshrc."
  fi

  if ! grep -qF 'NVM_DIR' "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" << 'BLOCK'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
BLOCK
    ok "Added NVM config to ~/.zshrc."
  fi

  if ! grep -qF '.cargo/env' "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" << 'BLOCK'

# Cargo (Rust)
[ -f "$HOME/.cargo/env" ] && \. "$HOME/.cargo/env"
BLOCK
    ok "Added Cargo config to ~/.zshrc."
  fi

  if ! grep -qF 'DENO_INSTALL' "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" << 'BLOCK'

# Deno
export DENO_INSTALL="$HOME/.deno"
[ -d "$DENO_INSTALL" ] && export PATH="$DENO_INSTALL/bin:$PATH"
BLOCK
    ok "Added Deno config to ~/.zshrc."
  fi
fi

# ── 2. SSH Key ───────────────────────────────────────────

section "SSH Key"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
SSH_KEY_PATH_RSA="$HOME/.ssh/id_rsa"

if [[ -f "$SSH_KEY_PATH.pub" ]]; then
  ok "Found existing key ($SSH_KEY_PATH.pub)"
elif [[ -f "$SSH_KEY_PATH_RSA.pub" ]]; then
  SSH_KEY_PATH="$SSH_KEY_PATH_RSA"
  ok "Found existing key ($SSH_KEY_PATH_RSA.pub)"
else
  echo "  No SSH key found."
  if ask "  Generate a new ed25519 SSH key?"; then
    mkdir -p "$HOME/.ssh"
    if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
      ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -q
    else
      read -rp "  Email for the key (or leave blank): " ssh_email < /dev/tty
      if [[ -n "$ssh_email" ]]; then
        ssh-keygen -t ed25519 -C "$ssh_email" -f "$SSH_KEY_PATH" < /dev/tty
      else
        ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" < /dev/tty
      fi
    fi
    eval "$(ssh-agent -s)" 2>/dev/null || true
    ssh-add "$SSH_KEY_PATH" 2>/dev/null || true
    track "SSH Key" "installed"
  else
    track "SSH Key" "skipped"
  fi
fi

# Always print the public key if one exists
if [[ -f "$SSH_KEY_PATH.pub" ]]; then
  echo ""
  echo -e "  ${BOLD}Your public SSH key (copy this to share with team / add to GitHub):${RESET}"
  echo ""
  echo -e "  ${YELLOW}$(cat "$SSH_KEY_PATH.pub")${RESET}"
  echo ""
fi

# WSL: ssh-agent doesn't persist across sessions. Add an auto-start snippet
# to shell RC files so keys are loaded on every new terminal.
# Runs for any existing key (new or pre-existing). The .zshrc template we
# created earlier already includes this, so the grep guard skips duplicates.
if $WSL && [[ -f "$SSH_KEY_PATH.pub" ]]; then
  SSH_AGENT_SNIPPET='
# SSH agent (WSL) — auto-start so keys persist across sessions
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" >/dev/null 2>&1
  find ~/.ssh -name "id_*" ! -name "*.pub" -exec ssh-add {} \; 2>/dev/null
fi'
  # Add to .bashrc (always exists on Ubuntu/WSL)
  if [[ -f "$HOME/.bashrc" ]] && ! grep -qF "SSH agent (WSL)" "$HOME/.bashrc"; then
    echo "$SSH_AGENT_SNIPPET" >> "$HOME/.bashrc"
    ok "Added ssh-agent auto-start to ~/.bashrc."
  fi
  # Add to .zshrc if it exists and doesn't already have it
  if [[ -f "$HOME/.zshrc" ]] && ! grep -qF "SSH agent (WSL)" "$HOME/.zshrc"; then
    echo "$SSH_AGENT_SNIPPET" >> "$HOME/.zshrc"
    ok "Added ssh-agent auto-start to ~/.zshrc."
  fi
fi

# ── 3. Homebrew (macOS only) ─────────────────────────────

if [[ "$OS" == "macos" ]]; then
  section "Homebrew"
  if command -v brew >/dev/null 2>&1; then
    ok "Already installed."
  else
    if ask "  Install Homebrew?"; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      track "Homebrew" "installed"
    else
      echo -e "  ${YELLOW}Skipped — some tools below require Homebrew.${RESET}"
      track "Homebrew" "skipped"
    fi
  fi
  reload_config
fi

# ── 4. NVM + Node.js LTS ─────────────────────────────────

section "NVM & Node.js LTS"
NVM_DIR="$HOME/.nvm"
# nvm.sh has unbound variables that conflict with set -u, so we disable it
# for the entire NVM block (sourcing, installing, and nvm commands).
set +u
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  \. "$NVM_DIR/nvm.sh" --no-use 2>/dev/null || true
  ok "NVM already installed."
else
  if ask "  Install NVM + Node.js LTS?"; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
    track "NVM" "installed"
  else
    track "NVM" "skipped"
  fi
fi

if type nvm >/dev/null 2>&1; then
  if command -v node >/dev/null 2>&1; then
    ok "Node.js already installed ($(node --version))."
  else
    echo "  Node.js is not installed."
    if ask "  Install latest LTS Node?"; then
      nvm install --lts --latest-npm
      nvm use --lts
      nvm alias default lts/*
      track "Node.js LTS" "installed"
    else
      track "Node.js LTS" "skipped"
    fi
  fi
fi
set -u
reload_config

# ── 5. PNPM ──────────────────────────────────────────────

section "PNPM"
if command -v pnpm >/dev/null 2>&1; then
  ok "Already installed ($(pnpm --version))."
else
  if command -v corepack >/dev/null 2>&1; then
    if ask "  Enable PNPM via corepack?"; then
      corepack enable pnpm
      corepack prepare pnpm@latest --activate
      track "PNPM" "installed"
    else
      track "PNPM" "skipped"
    fi
  else
    echo -e "  ${DIM}Corepack not available — install Node.js first to enable PNPM.${RESET}"
    track "PNPM" "skipped"
  fi
fi

# ── 6. Deno ──────────────────────────────────────────────

section "Deno"
if command -v deno >/dev/null 2>&1; then
  ok "Already installed."
else
  if ask "  Install Deno?"; then
    curl -fsSL https://deno.land/install.sh | sh
    track "Deno" "installed"
  else
    track "Deno" "skipped"
  fi
fi

# ── 7. Rust ──────────────────────────────────────────────

section "Rust"
if command -v rustc >/dev/null 2>&1; then
  ok "Already installed."
else
  if ask "  Install Rust (via rustup)?"; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    track "Rust" "installed"
  else
    track "Rust" "skipped"
  fi
fi
reload_config

# ── Language Servers (LSP) ──────────────────────────────
# Gives AI agents and editors rich code intelligence (go-to-definition,
# diagnostics, completions). Only installs servers for runtimes already present.

section "Language Servers (LSP)"

lsp_any_installed=false

# TypeScript / JavaScript — typescript-language-server (npm)
if command -v node >/dev/null 2>&1; then
  if command -v typescript-language-server >/dev/null 2>&1; then
    ok "typescript-language-server — already installed."
  elif ask "  Install typescript-language-server (TypeScript/JS LSP)?"; then
    npm install -g typescript typescript-language-server
    lsp_any_installed=true
    track "typescript-language-server" "installed"
  else
    track "typescript-language-server" "skipped"
  fi
  echo ""
else
  echo -e "  ${DIM}Node.js not installed — skipping typescript-language-server.${RESET}"
  echo ""
fi

# Python — pyright (npm, by Microsoft — industry standard)
if command -v node >/dev/null 2>&1; then
  if command -v pyright >/dev/null 2>&1; then
    ok "pyright — already installed."
  elif ask "  Install pyright (Python LSP)?"; then
    npm install -g pyright
    lsp_any_installed=true
    track "pyright" "installed"
  else
    track "pyright" "skipped"
  fi
  echo ""
else
  echo -e "  ${DIM}Node.js not installed — skipping pyright.${RESET}"
  echo ""
fi

# Rust — rust-analyzer (rustup component)
if command -v rustup >/dev/null 2>&1; then
  if rustup component list --installed 2>/dev/null | grep -q rust-analyzer; then
    ok "rust-analyzer — already installed."
  elif ask "  Install rust-analyzer (Rust LSP)?"; then
    rustup component add rust-analyzer
    lsp_any_installed=true
    track "rust-analyzer" "installed"
  else
    track "rust-analyzer" "skipped"
  fi
  echo ""
else
  echo -e "  ${DIM}Rust not installed — skipping rust-analyzer.${RESET}"
  echo ""
fi

# Go — gopls (official Go LSP)
if command -v go >/dev/null 2>&1; then
  if command -v gopls >/dev/null 2>&1; then
    ok "gopls — already installed."
  elif ask "  Install gopls (Go LSP)?"; then
    go install golang.org/x/tools/gopls@latest
    lsp_any_installed=true
    track "gopls" "installed"
  else
    track "gopls" "skipped"
  fi
  echo ""
else
  echo -e "  ${DIM}Go not installed — skipping gopls.${RESET}"
  echo ""
fi

if $lsp_any_installed; then
  reload_config
fi

# ── 8. Developer CLIs ───────────────────────────────────

section "Developer CLIs"

install_tool() {
  local cmd="$1" label="$2"
  shift 2
  # remaining args: macos_install_cmd... -- linux_install_cmd...
  # If no --, same command for both.

  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$label — already installed."
    return
  fi

  if ! ask "  Install $label?"; then
    track "$label" "skipped"
    return
  fi

  if [[ "$OS" == "macos" ]]; then
    eval "$1"
  else
    eval "$2"
  fi
  track "$label" "installed"
}

# Vercel CLI (npm — same on both)
install_tool "vercel" "Vercel CLI" \
  "npm install -g vercel" \
  "npm install -g vercel"
echo ""

# Supabase CLI
if command -v supabase >/dev/null 2>&1; then
  ok "Supabase CLI — already installed."
elif ask "  Install Supabase CLI?"; then
  if [[ "$OS" == "macos" ]]; then
    brew install supabase/tap/supabase
  else
    SUPA_VERSION=$(curl -fsSL https://api.github.com/repos/supabase/cli/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | sed 's/^v//')
    curl -fsSL "https://github.com/supabase/cli/releases/download/v${SUPA_VERSION}/supabase_${SUPA_VERSION}_linux_amd64.deb" -o /tmp/supabase.deb
    sudo dpkg -i /tmp/supabase.deb
    rm -f /tmp/supabase.deb
  fi
  track "Supabase CLI" "installed"
else
  track "Supabase CLI" "skipped"
fi
echo ""

# GitHub CLI
if command -v gh >/dev/null 2>&1; then
  ok "GitHub CLI — already installed."
elif ask "  Install GitHub CLI?"; then
  if [[ "$OS" == "macos" ]]; then
    brew install gh
  else
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update && sudo apt-get install -y gh
  fi
  track "GitHub CLI" "installed"
else
  track "GitHub CLI" "skipped"
fi
echo ""

# Stripe CLI
if command -v stripe >/dev/null 2>&1; then
  ok "Stripe CLI — already installed."
elif ask "  Install Stripe CLI?"; then
  if [[ "$OS" == "macos" ]]; then
    brew install stripe/stripe-cli/stripe
  else
    curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor | sudo tee /usr/share/keyrings/stripe.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" | sudo tee /etc/apt/sources.list.d/stripe.list >/dev/null
    sudo apt-get update && sudo apt-get install -y stripe
  fi
  track "Stripe CLI" "installed"
else
  track "Stripe CLI" "skipped"
fi
echo ""

# PostgreSQL CLI (psql)
install_tool "psql" "PostgreSQL CLI (psql)" \
  "brew install libpq && brew link --force libpq" \
  "sudo apt-get update && sudo apt-get install -y postgresql-client"
echo ""

# AWS CLI (special — different install method per OS)
if command -v aws >/dev/null 2>&1; then
  ok "AWS CLI — already installed."
elif ask "  Install AWS CLI v2?"; then
  if [[ "$OS" == "macos" ]]; then
    curl -s "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "/tmp/AWSCLIV2.pkg"
    sudo installer -pkg /tmp/AWSCLIV2.pkg -target /
    rm -f /tmp/AWSCLIV2.pkg
  else
    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
      AWS_ARCH="aarch64"
    else
      AWS_ARCH="x86_64"
    fi
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "/tmp/awscliv2.zip"
    unzip -qo /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip
  fi
  track "AWS CLI" "installed"
else
  track "AWS CLI" "skipped"
fi
echo ""

# jq (JSON processor)
if command -v jq >/dev/null 2>&1; then
  ok "jq — already installed."
elif ask "  Install jq (JSON processor)?"; then
  if [[ "$OS" == "macos" ]]; then
    brew install jq
  else
    sudo apt-get install -y jq
  fi
  track "jq" "installed"
else
  track "jq" "skipped"
fi

reload_config

# ── 9. Service Logins ───────────────────────────────────

section "Service Logins"

if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
  echo -e "  ${DIM}Skipping logins (non-interactive mode).${RESET}"
  echo ""
else
  echo "Already-authenticated services are automatically skipped."
  if $WSL; then
    echo -e "${DIM}  WSL: Login commands will print a URL — open it in your Windows browser.${RESET}"
    echo -e "${DIM}  If a login hangs, press Ctrl+C to skip it. You can always log in later.${RESET}"
  fi
  echo ""

  if command -v vercel >/dev/null 2>&1; then
    if vercel whoami >/dev/null 2>&1; then
      ok "Vercel — already logged in ($(vercel whoami 2>/dev/null))."
    elif ask "  Log in to Vercel?"; then
      vercel login < /dev/tty || echo -e "  ${YELLOW}Vercel login incomplete — run 'vercel login' later to finish.${RESET}"
    fi
    echo ""
  fi

  if command -v supabase >/dev/null 2>&1; then
    if supabase projects list >/dev/null 2>&1; then
      ok "Supabase — already logged in."
    elif ask "  Log in to Supabase?"; then
      supabase login < /dev/tty || echo -e "  ${YELLOW}Supabase login incomplete — run 'supabase login' later to finish.${RESET}"
    fi
    echo ""
  fi

  if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
      ok "GitHub — already logged in."
    elif ask "  Log in to GitHub?"; then
      gh auth login < /dev/tty || echo -e "  ${YELLOW}GitHub login incomplete — run 'gh auth login' later to finish.${RESET}"
    fi
    echo ""
  fi

  if command -v aws >/dev/null 2>&1; then
    if aws sts get-caller-identity >/dev/null 2>&1; then
      ok "AWS — already configured."
    elif ask "  Configure AWS credentials?"; then
      aws configure < /dev/tty || echo -e "  ${YELLOW}AWS config incomplete — run 'aws configure' later to finish.${RESET}"
    fi
    echo ""
  fi

  if command -v stripe >/dev/null 2>&1; then
    if stripe config --list >/dev/null 2>&1; then
      ok "Stripe — already logged in."
    elif ask "  Log in to Stripe?"; then
      stripe login < /dev/tty || echo -e "  ${YELLOW}Stripe login incomplete — run 'stripe login' later to finish.${RESET}"
    fi
    echo ""
  fi
fi

# ── 10. Claude Code CLI ─────────────────────────────────

section "Claude Code CLI"
if command -v claude >/dev/null 2>&1; then
  ok "Already installed."
else
  if ask "  Install Claude Code CLI?"; then
    curl -fsSL https://claude.ai/install.sh | bash
    track "Claude Code" "installed"
  else
    track "Claude Code" "skipped"
  fi
fi

# Offer the `claw` alias for bypass-permissions mode
CLAW_ALIAS="alias claw='claude --permission-mode bypassPermissions --'"

# Detect the right shell config file.
# On Linux, check the configured login shell (handles mid-script chsh to zsh).
# $SHELL reflects the shell at script start, not necessarily what chsh just set.
login_shell="$SHELL"
if [[ "$OS" == "linux" ]]; then
  login_shell=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")
fi

if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$login_shell" == */zsh ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ -n "${BASH_VERSION:-}" ]] || [[ "$login_shell" == */bash ]]; then
  # Prefer .bash_profile on macOS (login shell), .bashrc on Linux
  if [[ "$OS" == "macos" ]]; then
    SHELL_RC="$HOME/.bash_profile"
  else
    SHELL_RC="$HOME/.bashrc"
  fi
else
  SHELL_RC="$HOME/.profile"
fi

# Clean up malformed claw alias from a previous run (raw ANSI escape codes baked in)
if grep -q '\\033\[' "$SHELL_RC" 2>/dev/null && grep -q 'claw' "$SHELL_RC" 2>/dev/null; then
  sed -i '/\\033\[.*claw/d' "$SHELL_RC" 2>/dev/null || true
  sed -i '/^# VibeStack:.*permission/d' "$SHELL_RC" 2>/dev/null || true
  ok "Removed malformed claw alias from $SHELL_RC."
fi

# Check all common RC files, not just the detected one
claw_found=false
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
  if [[ -f "$rc" ]] && grep -qF "alias claw=" "$rc" 2>/dev/null; then
    claw_found=true
    break
  fi
done

if $claw_found; then
  ok "claw alias — already configured."
else
  echo -e "  The ${BOLD}claw${RESET} alias runs Claude in bypass-permissions mode:"
  echo ""
  echo -e "    ${DIM}${CLAW_ALIAS}${RESET}"
  echo ""
  echo "  VibeStack's philosophy is that AI agents should run uninterrupted."
  echo "  Safety belongs in CI — linters, tests, and pre-commit hooks — not"
  echo "  in interactive permission prompts that slow the agent down."
  echo ""
  if ask "  Add the claw alias to $SHELL_RC?"; then
    echo "" >> "$SHELL_RC"
    echo "# VibeStack: run Claude without permission prompts (safety enforced via CI)" >> "$SHELL_RC"
    echo "$CLAW_ALIAS" >> "$SHELL_RC"
    ok "Added to $SHELL_RC — available after restarting your terminal."
    track "claw alias" "installed"
  else
    track "claw alias" "skipped"
  fi
fi

# ── 11. VS Code ─────────────────────────────────────────

section "VS Code"
if command -v code >/dev/null 2>&1; then
  ok "Already installed."
elif [[ "$OS" == "macos" && -d "/Applications/Visual Studio Code.app" ]]; then
  ok "Already installed (found in /Applications)."
  echo -e "  ${DIM}Tip: Open VS Code and run 'Shell Command: Install code command in PATH' from the command palette.${RESET}"
else
  if ask "  Install Visual Studio Code?"; then
    if [[ "$OS" == "macos" ]]; then
      if command -v brew >/dev/null 2>&1; then
        brew install --cask visual-studio-code
        track "VS Code" "installed"
      else
        echo -e "  ${YELLOW}Homebrew not available — install Homebrew first or download VS Code manually.${RESET}"
        track "VS Code" "skipped"
      fi
    else
      if $WSL; then
        echo -e "  ${YELLOW}On WSL, install VS Code on Windows and use the WSL extension instead.${RESET}"
        echo -e "  ${DIM}Download: https://code.visualstudio.com/Download${RESET}"
        echo -e "  ${DIM}Then install the 'WSL' extension and run 'code .' from your WSL terminal.${RESET}"
        track "VS Code" "skipped"
      else
        # Install via Microsoft apt repo (works better than snap on headless/WSL)
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
        sudo apt-get update && sudo apt-get install -y code
        track "VS Code" "installed"
      fi
    fi
  else
    track "VS Code" "skipped"
  fi
fi

# Install Claude Code extension if VS Code CLI is available
if command -v code >/dev/null 2>&1; then
  echo ""
  if code --list-extensions 2>/dev/null | grep -q "anthropic.claude-code"; then
    ok "Claude Code extension — already installed."
  elif ask "  Install Claude Code extension for VS Code?"; then
    code --install-extension anthropic.claude-code
    track "Claude Code Extension" "installed"
  else
    track "Claude Code Extension" "skipped"
  fi
fi

# ── 12. Vim Syntax Highlighting ──────────────────────────

section "Vim Syntax Highlighting"
vim_configured=false
for vf in "$HOME/.vimrc" "$HOME/.vim/vimrc" "$HOME/.config/nvim/init.vim" "$HOME/.config/nvim/init.lua"; do
  if [[ -f "$vf" ]]; then
    vim_configured=true
    break
  fi
done

if $vim_configured; then
  ok "Vim config already exists — skipping."
else
  echo "  Adds syntax highlighting, line numbers, and sensible defaults to Vim."
  echo ""
  if ask "  Configure Vim syntax highlighting?"; then
    if [[ ! -f "$HOME/.vimrc" ]]; then
      cat > "$HOME/.vimrc" << 'VIMRC'
" ~/.vimrc — sensible defaults (added by vibestack installer)
syntax on
filetype plugin indent on
set number
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set hlsearch
set incsearch
set ignorecase
set smartcase
set backspace=indent,eol,start
VIMRC
      ok "Created ~/.vimrc with syntax highlighting and sensible defaults."
    else
      cat >> "$HOME/.vimrc" << 'VIMRC'

" Syntax highlighting (added by vibestack installer)
syntax on
filetype plugin indent on
VIMRC
      ok "Added syntax highlighting to existing ~/.vimrc."
    fi
    track "Vim syntax highlighting" "installed"
  else
    track "Vim syntax highlighting" "skipped"
  fi
fi

# ── 13. Xcode Command Line Tools (macOS only — last, large download)

if [[ "$OS" == "macos" ]]; then
  section "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    ok "Already installed."
  else
    echo "  Xcode Command Line Tools are not installed."
    echo "  This is a large download but provides essential build tools (git, make, clang, etc.)."
    echo ""
    if ask "  Install Xcode Command Line Tools?"; then
      xcode-select --install
      echo ""
      echo -e "  ${YELLOW}A system dialog should have appeared. Complete the installation there.${RESET}"
      echo -e "  ${YELLOW}Re-run this script afterwards if you skipped anything above.${RESET}"
      track "Xcode CLT" "installed"
    else
      track "Xcode CLT" "skipped"
    fi
  fi
fi

# ── Summary ──────────────────────────────────────────────

echo ""
echo -e "${CYAN}${DIVIDER}${RESET}"
echo -e "${GREEN}${BOLD} Done!${RESET}"
echo -e "${CYAN}${DIVIDER}${RESET}"

if [[ ${#installed[@]} -gt 0 ]]; then
  echo -e "\n  ${GREEN}Installed:${RESET}"
  for item in "${installed[@]}"; do
    echo "    + $item"
  done
fi

if [[ ${#installed[@]} -eq 0 && ${#skipped[@]} -eq 0 ]]; then
  echo -e "\n  Everything was already set up. Nothing to do."
fi

if [[ ${#skipped[@]} -gt 0 ]]; then
  echo -e "\n  ${DIM}Skipped / Already installed:${RESET}"
  for item in "${skipped[@]}"; do
    echo -e "    ${DIM}- $item${RESET}"
  done
fi

echo ""
echo "Restart your terminal to ensure all tools are available."
echo ""
