#!/usr/bin/env bash
# Test the v2 VibeStack installer — user-level settings + plugin install bootstrap.
#
# In v2, install.sh ONLY:
#   1. Detects/offers to install the Claude CLI
#   2. Deep-merges ~/.claude/settings.json (with two clobber paths)
#   3. Runs `claude plugin install` if Claude is available
#
# Skills, hooks, and templates come from the VibeStack plugin (not curl|bash).
# In Docker, `claude` is NOT installed, so the plugin install branch is silently
# skipped and the fallback message is printed instead.

set -euo pipefail

CYAN="\033[0;36m"
RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"

pass=0
fail=0

assert_file_exists() {
  if [[ -f "$1" ]]; then
    echo -e "  ${GREEN}PASS${RESET}  $1 exists"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $1 missing"
    ((++fail))
  fi
}

assert_file_absent() {
  if [[ ! -e "$1" ]]; then
    echo -e "  ${GREEN}PASS${RESET}  $1 not present (correct for v2 — plugin owns this)"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $1 should not exist (file drops moved to plugin install path)"
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

assert_output_contains() {
  if echo "$1" | sed 's/\x1b\[[0-9;]*m//g' | grep -qE "$2"; then
    echo -e "  ${GREEN}PASS${RESET}  Output contains '$2'"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  Output missing '$2'"
    ((++fail))
  fi
}

echo -e "${CYAN}=== Test: VibeStack v2 Installer (user-level) ===${RESET}"
echo ""

mkdir -p /workspace
cd /workspace
output=$(SKIP_DEVTOOLS=1 VIBESTACK_REPO="${VIBESTACK_REPO:-file:///vibestack}" bash /vibestack/install.sh 2>&1) || true
echo "$output"

USER_DIR="$HOME/.claude"

echo ""
echo -e "${CYAN}--- settings.json was written ---${RESET}"

assert_file_exists "$USER_DIR/settings.json"
assert_file_contains "$USER_DIR/settings.json" "skipDangerousModePermissionPrompt"
assert_file_contains "$USER_DIR/settings.json" "statusLine"
assert_file_contains "$USER_DIR/settings.json" "bypassPermissions"
if grep -q "CLAUDE_PROJECT_DIR" "$USER_DIR/settings.json" 2>/dev/null; then
  echo -e "  ${RED}FAIL${RESET}  settings.json references \$CLAUDE_PROJECT_DIR"
  ((++fail))
else
  echo -e "  ${GREEN}PASS${RESET}  settings.json does not reference \$CLAUDE_PROJECT_DIR"
  ((++pass))
fi

echo ""
echo -e "${CYAN}--- File drops removed (plugin owns these) ---${RESET}"

# These used to come from curl|bash directly. They now come from the plugin.
assert_file_absent "$USER_DIR/skills"
assert_file_absent "$USER_DIR/hooks"

echo ""
echo -e "${CYAN}--- Project directory remains untouched ---${RESET}"

assert_file_absent "/workspace/CLAUDE.md"
assert_file_absent "/workspace/Makefile"
assert_file_absent "/workspace/docs"
assert_file_absent "/workspace/.claude"

echo ""
echo -e "${CYAN}--- Output messaging (Claude CLI absent in Docker) ---${RESET}"

# In Docker, claude isn't installed and ask_yes returns true under NONINTERACTIVE=1.
# Either: (a) the install attempt failed (curl can't reach claude.ai), and we get
# the fallback message, OR (b) the install succeeded and plugin install ran.
# We accept either — the script should not crash.
assert_output_contains "$output" "Claude CLI"

echo ""
echo -e "${CYAN}--- Re-run installer (idempotency) ---${RESET}"

output2=$(SKIP_DEVTOOLS=1 VIBESTACK_REPO="${VIBESTACK_REPO:-file:///vibestack}" bash /vibestack/install.sh 2>&1) || true
clean_output=$(echo "$output2" | sed 's/\x1b\[[0-9;]*m//g')

if echo "$clean_output" | grep -qE "merge|Settings ready"; then
  echo -e "  ${GREEN}PASS${RESET}  Re-run merges settings without crashing"
  ((++pass))
else
  echo -e "  ${RED}FAIL${RESET}  Re-run did not report a successful settings merge"
  ((++fail))
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
