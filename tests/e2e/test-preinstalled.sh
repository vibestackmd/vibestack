#!/usr/bin/env bash
# Test installer behavior when the user already has a populated ~/.claude/.
# Validates the settings.json deep-merge preserves the user's existing values.
set -euo pipefail

CYAN="\033[0;36m"
RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"

pass=0
fail=0

assert_file_contains() {
  if grep -q "$2" "$1" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${RESET}  $1 contains '$2'"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $1 does not contain '$2'"
    ((++fail))
  fi
}

assert_json_value() {
  local file="$1" key="$2" expected="$3"
  local actual
  actual=$(/usr/bin/python3 -c "import json,sys; print(json.load(open('$file')).get('$key', ''))" 2>/dev/null)
  if [[ "$actual" == "$expected" ]]; then
    echo -e "  ${GREEN}PASS${RESET}  $file['$key'] = '$expected'"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $file['$key'] = '$actual' (expected '$expected')"
    ((++fail))
  fi
}

USER_DIR="$HOME/.claude"

echo -e "${CYAN}=== Test: Pre-existing User Config (settings merge) ===${RESET}"
echo ""

echo -e "${CYAN}--- Verifying pre-existing user settings ---${RESET}"
assert_file_contains "$USER_DIR/settings.json" "user-custom-key"

echo ""
echo -e "${CYAN}--- Running v2 installer ---${RESET}"

mkdir -p /workspace
cd /workspace
output=$(SKIP_DEVTOOLS=1 VIBESTACK_REPO="${VIBESTACK_REPO:-file:///vibestack}" bash /vibestack/install.sh 2>&1) || true
echo "$output"

echo ""
echo -e "${CYAN}--- User's existing values preserved ---${RESET}"

# Custom user key must survive the merge
assert_file_contains "$USER_DIR/settings.json" "user-custom-key"

echo ""
echo -e "${CYAN}--- VibeStack values added where absent ---${RESET}"

# These keys weren't in the user's pre-existing file, so they should now be present.
# Note: the Stop hook lives in hooks/hooks.json under the plugin root and statusLine
# lives in user-level settings.json with a path pointing to ~/.claude/hooks/statusline.sh
# (which install.sh drops). enabledPlugins is NOT in user.settings.json, chain-install
# via plugin.json `dependencies` is the single source of truth.
assert_file_contains "$USER_DIR/settings.json" "skipDangerousModePermissionPrompt"
assert_file_contains "$USER_DIR/settings.json" "statusLine"

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
