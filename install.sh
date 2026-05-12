#!/usr/bin/env bash
# VibeStack Installer (v2 — user-level)
# Installs VibeStack skills, hooks, and settings into the user's ~/.claude/
# directory so they apply across every project on this machine.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/vibestackmd/vibestack/main/install.sh | bash

set -euo pipefail

REPO="${VIBESTACK_REPO:-https://raw.githubusercontent.com/vibestackmd/vibestack/main}"
USER_DIR="$HOME/.claude"

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
DIM="\033[2m"
RESET="\033[0m"

echo -e "${CYAN}▓▒░ VibeStack Installer${RESET}"
echo -e "${DIM}Installing to $USER_DIR${RESET}"
echo ""

# Skills, hooks, and the plugin's own settings.json all come from the VibeStack
# Claude plugin (installed via `claude plugin install` below). curl|bash only
# handles the things plugins can't: user-level settings.json keys (defaultMode,
# enabledPlugins, voiceEnabled, companyAnnouncements...), Claude CLI auto-install,
# and triggering the plugin install. The user-level keys live in user.settings.json
# at the repo root — separate from the plugin's hook/statusLine settings.json.
SETTINGS_PATH="user.settings.json"

installed=0
merged=0

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

# ── Claude CLI preflight ──────────────────────────────────
# VibeStack needs `claude` on $PATH so we can chain-install plugins on the
# user's behalf. If it's missing, offer the official curl installer.

CLAUDE_AVAILABLE=false
if command -v claude >/dev/null 2>&1; then
  CLAUDE_AVAILABLE=true
  echo -e "${DIM}Claude CLI detected: $(claude --version 2>/dev/null | head -1)${RESET}"
else
  echo -e "${YELLOW}Claude CLI not found on \$PATH.${RESET}"
  echo "  VibeStack ships skills, hooks, and settings — but the LSP and frontend-design"
  echo "  plugins need the Claude CLI to install. Without it, those plugins won't be set up."
  echo ""
  if ask_yes "  Install Claude CLI now (via official installer)?"; then
    if curl -fsSL https://claude.ai/install.sh | bash; then
      # The installer drops claude into ~/.local/bin or similar; pick it up
      # for the rest of this script run.
      for candidate in "$HOME/.local/bin" "$HOME/.claude/local/bin"; do
        if [[ -x "$candidate/claude" ]]; then
          export PATH="$candidate:$PATH"
          break
        fi
      done
      if command -v claude >/dev/null 2>&1; then
        echo -e "  ${GREEN}Claude CLI installed.${RESET}"
        CLAUDE_AVAILABLE=true
      else
        echo -e "  ${YELLOW}Claude installer ran but \`claude\` is still not on \$PATH.${RESET}"
        echo "  You may need to open a new shell. Plugin install will be skipped."
      fi
    else
      echo -e "  ${YELLOW}Claude install failed. Plugin install will be skipped.${RESET}"
    fi
  else
    echo -e "  ${DIM}Skipping plugin install. You can install Claude CLI later from https://claude.ai/install.sh${RESET}"
  fi
fi
echo ""

# Deep-merge settings.json. Existing user values win except for two clobber
# paths (skipDangerousModePermissionPrompt and permissions.defaultMode), which
# are the framework's load-bearing opinions and overwrite unconditionally.
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

# Paths VibeStack overrides unconditionally — these define the core opinion
# of the framework and clobber any prior user setting after the merge.
CLOBBER_PATHS = [
    ('skipDangerousModePermissionPrompt',),
    ('permissions', 'defaultMode'),
]

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

def get_path(d, path):
    cur = d
    for k in path:
        if not isinstance(cur, dict) or k not in cur:
            return None
        cur = cur[k]
    return cur

def set_path(d, path, value):
    cur = d
    for k in path[:-1]:
        if k not in cur or not isinstance(cur[k], dict):
            cur[k] = {}
        cur = cur[k]
    cur[path[-1]] = value

with open(sys.argv[1]) as f:
    existing = json.load(f)
with open(sys.argv[2]) as f:
    incoming = json.load(f)

merged = deep_merge(existing, incoming)

# Apply clobbers after merge so VibeStack's load-bearing opinions win
# regardless of what the user had before.
for path in CLOBBER_PATHS:
    val = get_path(incoming, path)
    if val is not None:
        set_path(merged, path, val)

print(json.dumps(merged, indent=2))
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
echo -e "${GREEN}Settings ready.${RESET} Added $installed, merged $merged."

# ── User-level hook scripts ──────────────────────────────
# The main statusLine is registered in user-level settings.json (plugins can
# only ship subagentStatusLine, not the main statusLine). The script it runs
# has to exist at a stable user-level path, so we drop it into ~/.claude/hooks/
# alongside settings.json. The Stop hook stays plugin-scoped via hooks/hooks.json.
mkdir -p "$USER_DIR/hooks"
if curl -fsSL "$REPO/hooks/statusline.sh" -o "$USER_DIR/hooks/statusline.sh"; then
  chmod +x "$USER_DIR/hooks/statusline.sh"
  echo -e "  ${GREEN}ok${RESET}    ~/.claude/hooks/statusline.sh"
else
  echo -e "  ${YELLOW}fail${RESET}  ~/.claude/hooks/statusline.sh (statusLine will not render)"
fi

# ── Plugin install ──────────────────────────────────────
# Install the VibeStack plugin via Claude. Its `dependencies` field chain-
# installs the LSP plugins and frontend-design automatically. Cross-marketplace
# resolution is allowed by marketplace.json's allowCrossMarketplaceDependenciesOn.
# Skipped silently if claude isn't available.

if $CLAUDE_AVAILABLE; then
  echo ""
  echo -e "${CYAN}── Installing Claude plugins ──${RESET}"
  echo ""

  # Marketplace ref. Defaults to the published GitHub repo; tests override this
  # to a local-path marketplace built by `make plugin` (see dist/test-marketplace/).
  MARKETPLACE_REF="${VIBESTACK_MARKETPLACE:-vibestackmd/vibestack}"

  # Set VIBESTACK_DEBUG=1 to surface stderr from claude commands. Default is
  # quiet so re-runs (where the marketplace is already added) don't look noisy.
  if [[ "${VIBESTACK_DEBUG:-0}" == "1" ]]; then
    redirect=""
  else
    redirect=">/dev/null 2>&1"
  fi

  # Add claude-plugins-official first — it serves the LSP + frontend-design
  # plugins that VibeStack declares as cross-marketplace dependencies. Fresh
  # Claude installs have no marketplaces configured, so this must be explicit.
  if eval "claude plugin marketplace add anthropics/claude-plugins-official $redirect"; then
    echo -e "  ${GREEN}ok${RESET}    marketplace: anthropics/claude-plugins-official"
  else
    echo -e "  ${DIM}note${RESET}  marketplace: anthropics/claude-plugins-official (already added or failed — continuing)"
  fi

  # Then add the VibeStack marketplace. allowCrossMarketplaceDependenciesOn in
  # our marketplace.json permits depending on claude-plugins-official.
  if eval "claude plugin marketplace add \"$MARKETPLACE_REF\" $redirect"; then
    echo -e "  ${GREEN}ok${RESET}    marketplace: $MARKETPLACE_REF"
  else
    echo -e "  ${DIM}note${RESET}  marketplace: $MARKETPLACE_REF (already added or failed — continuing)"
  fi

  # Install vibestack — its dependencies handle the rest.
  if eval "claude plugin install \"vibestack@vibestackmd-vibestack\" --scope user $redirect"; then
    echo -e "  ${GREEN}ok${RESET}    vibestack@vibestackmd-vibestack (+ chain-installed dependencies)"
  else
    echo -e "  ${YELLOW}skip${RESET}  vibestack plugin install failed — run \`claude plugin install vibestack@vibestackmd-vibestack\` manually"
  fi
fi

# ── Optional: Dev Tools Installer ───────────────────────

DEV_TOOLS_REPO="https://raw.githubusercontent.com/vibestackmd/vibestack/main/extras/dev-tools"

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
if ! $CLAUDE_AVAILABLE; then
  echo ""
  echo "  ${YELLOW}Plugin install was skipped${RESET} (Claude CLI not available)."
  echo "  Once you install Claude CLI, run these to finish setup:"
  echo ""
  echo "    claude plugin marketplace add vibestackmd/vibestack"
  echo "    claude plugin install vibestack@vibestackmd-vibestack --scope user"
fi
echo ""
