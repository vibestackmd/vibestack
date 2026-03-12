#!/usr/bin/env bash
# Test WSL-specific behavior with a simulated WSL environment.
# The container has a fake /proc/version mounted with "microsoft" in it.
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

echo -e "${CYAN}=== Test: WSL Detection ===${RESET}"
echo ""

# Verify fake /proc/version is in place
echo -e "${CYAN}--- Checking WSL simulation ---${RESET}"
if grep -qi microsoft /proc/version 2>/dev/null; then
  echo -e "  ${GREEN}PASS${RESET}  /proc/version contains 'microsoft'"
  ((++pass))
else
  echo -e "  ${RED}FAIL${RESET}  /proc/version does not contain 'microsoft' — WSL simulation broken"
  ((++fail))
fi

echo ""
echo -e "${CYAN}--- Running dev-tools installer ---${RESET}"

export NONINTERACTIVE="${NONINTERACTIVE:-1}"
bash /vibestack/kit/extras/dev-tools/install.sh || true

echo ""
echo -e "${CYAN}--- Checking WSL-specific results ---${RESET}"

# The dev-tools installer should have created .zshrc with WSL-specific content
# This proves WSL was detected regardless of how output was captured
assert_file_contains "$HOME/.zshrc" "SSH agent"
assert_file_contains "$HOME/.zshrc" "ssh-agent"

# .bashrc should also have the SSH agent snippet on WSL
if [[ -f "$HOME/.bashrc" ]]; then
  assert_file_contains "$HOME/.bashrc" "SSH agent"
fi

echo ""
echo -e "${CYAN}--- Running main installer (WSL detection) ---${RESET}"

cd /workspace
SKIP_DEVTOOLS=1 bash /vibestack/install.sh > /tmp/main-output.txt 2>&1 || true
cat /tmp/main-output.txt

# Main installer's dev-tools section should mention WSL
# Using SKIP_DEVTOOLS skips the whole block, so check the dev-tools description text instead
# which prints before the SKIP_DEVTOOLS check
if sed 's/\x1b\[[0-9;]*m//g' /tmp/main-output.txt | grep -qiE "WSL|Linux"; then
  echo -e "  ${GREEN}PASS${RESET}  Main installer ran on detected Linux/WSL"
  ((++pass))
else
  echo -e "  ${RED}FAIL${RESET}  Main installer did not detect Linux/WSL"
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
