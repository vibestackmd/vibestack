#!/usr/bin/env bash
# End-to-end test: build a local marketplace, run install.sh against it, and
# assert the about-to-ship plugin actually installs via the real Claude CLI.
#
# Unlike test-main-install.sh (which runs without `claude` on $PATH and so
# silently skips the plugin-install branch), this test validates the full
# `claude plugin marketplace add` + `claude plugin install` flow against a
# locally-built marketplace at /vibestack/dist/test-marketplace.

set -euo pipefail

CYAN="\033[0;36m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

pass=0
fail=0

ok() { echo -e "  ${GREEN}PASS${RESET}  $1"; ((++pass)); }
no() { echo -e "  ${RED}FAIL${RESET}  $1"; ((++fail)); }

assert_file_exists() {
  if [[ -f "$1" ]]; then ok "$1 exists"; else no "$1 missing"; fi
}

assert_dir_exists() {
  if [[ -d "$1" ]]; then ok "$1/ exists"; else no "$1/ missing"; fi
}

assert_output_contains() {
  if echo "$1" | sed 's/\x1b\[[0-9;]*m//g' | grep -qE "$2"; then
    ok "Output contains '$2'"
  else
    no "Output missing '$2'"
  fi
}

echo -e "${CYAN}=== Test: Local marketplace + real Claude CLI ===${RESET}"
echo ""

# ── Preflight ───────────────────────────────────────────
if ! command -v claude >/dev/null 2>&1; then
  echo -e "${RED}Claude CLI not on PATH — this test requires the local-marketplace Docker image.${RESET}"
  exit 1
fi
echo -e "${YELLOW}Claude CLI:${RESET} $(claude --version)"

VERSION=$(tr -d '[:space:]' < /vibestack/VERSION)
TEST_MARKET="/vibestack/dist/test-marketplace"

if [[ ! -f "$TEST_MARKET/.claude-plugin/marketplace.json" ]]; then
  echo -e "${RED}Test marketplace not found at $TEST_MARKET — run 'make plugin' on the host first.${RESET}"
  exit 1
fi

# ── Run installer against the local marketplace ─────────
echo ""
echo -e "${CYAN}--- Running install.sh with VIBESTACK_MARKETPLACE=$TEST_MARKET ---${RESET}"
echo ""

mkdir -p /workspace
cd /workspace
output=$(SKIP_DEVTOOLS=1 \
  VIBESTACK_REPO="file:///vibestack" \
  VIBESTACK_MARKETPLACE="$TEST_MARKET" \
  VIBESTACK_DEBUG=1 \
  bash /vibestack/install.sh 2>&1) || true
echo "$output"

# ── Assertions on installer output ──────────────────────
echo ""
echo -e "${CYAN}--- Installer reports marketplace + plugin install ---${RESET}"

assert_output_contains "$output" "marketplace: $TEST_MARKET"
assert_output_contains "$output" "vibestack@vibestackmd-vibestack"

# ── Assertions on Claude CLI state ──────────────────────
echo ""
echo -e "${CYAN}--- claude plugin marketplace list shows our marketplace ---${RESET}"

market_list=$(claude plugin marketplace list 2>&1 || true)
echo "$market_list"
assert_output_contains "$market_list" "vibestackmd-vibestack"

echo ""
echo -e "${CYAN}--- claude plugin list shows vibestack at version $VERSION ---${RESET}"

plugin_list=$(claude plugin list 2>&1 || true)
echo "$plugin_list"
assert_output_contains "$plugin_list" "vibestack"
assert_output_contains "$plugin_list" "$VERSION"

# Plugin must actually load — catches missing dependencies / bad manifests.
# Without this check, an install that succeeds but fails to load would pass.
clean_plugin_list=$(echo "$plugin_list" | sed 's/\x1b\[[0-9;]*m//g')
if echo "$clean_plugin_list" | grep -qE "failed to load|Error:"; then
  no "Plugin reports load error: $(echo "$clean_plugin_list" | grep -E 'failed to load|Error:' | head -2 | tr '\n' ' ')"
else
  ok "Plugin loads cleanly (no 'failed to load' / Error: in plugin list)"
fi

# ── Assertions on installed plugin files ────────────────
echo ""
echo -e "${CYAN}--- Plugin files landed under ~/.claude/plugins/cache/ ---${RESET}"

# Per the marketplace spec, plugins install to:
#   ~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/
PLUGIN_DIR="$HOME/.claude/plugins/cache/vibestackmd-vibestack/vibestack/$VERSION"

# Fall back to a glob if the exact path isn't there yet (Claude versions may
# differ in their on-disk layout). Find the actual path for diagnostics.
if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo -e "  ${YELLOW}note${RESET}  Expected $PLUGIN_DIR — searching for actual install location..."
  found=$(find "$HOME/.claude/plugins" -name "plugin.json" -path "*vibestack*" 2>/dev/null | head -5 || true)
  if [[ -n "$found" ]]; then
    echo "  Found plugin.json at:"
    echo "$found" | sed 's/^/    /'
    # Use the first match's parent dir for further assertions
    PLUGIN_DIR=$(dirname "$(dirname "$(echo "$found" | head -1)")")
    echo "  Using PLUGIN_DIR=$PLUGIN_DIR"
  fi
fi

assert_dir_exists "$PLUGIN_DIR"
assert_file_exists "$PLUGIN_DIR/.claude-plugin/plugin.json"
assert_dir_exists "$PLUGIN_DIR/skills"
assert_dir_exists "$PLUGIN_DIR/hooks"
assert_file_exists "$PLUGIN_DIR/skills/vibestack/SKILL.md"
assert_file_exists "$PLUGIN_DIR/hooks/notify-done.sh"
assert_file_exists "$PLUGIN_DIR/settings.json"

# ── Hook paths must reference ${CLAUDE_PLUGIN_ROOT}, not host paths ──
echo ""
echo -e "${CYAN}--- Plugin settings.json uses CLAUDE_PLUGIN_ROOT ---${RESET}"

if grep -q 'CLAUDE_PLUGIN_ROOT' "$PLUGIN_DIR/settings.json" 2>/dev/null; then
  ok "settings.json references \${CLAUDE_PLUGIN_ROOT}"
else
  no "settings.json missing \${CLAUDE_PLUGIN_ROOT} reference"
fi

if grep -qE '\$CLAUDE_PROJECT_DIR|\$HOME/\.claude/hooks/' "$PLUGIN_DIR/settings.json" 2>/dev/null; then
  no "settings.json contains unrewritten host paths"
else
  ok "settings.json has no host-path leakage"
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
