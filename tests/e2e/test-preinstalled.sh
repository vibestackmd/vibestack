#!/usr/bin/env bash
# Test installer behavior when project files and tools already exist.
# Validates skip logic and idempotency.
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

assert_output_contains() {
  # Write to temp file to avoid argument length limits, strip ANSI codes
  local tmpf
  tmpf=$(mktemp)
  echo "$1" > "$tmpf"
  if sed 's/\x1b\[[0-9;]*m//g' "$tmpf" | grep -qE "$2"; then
    echo -e "  ${GREEN}PASS${RESET}  Output contains '$2'"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  Output missing '$2'"
    ((++fail))
  fi
  rm -f "$tmpf"
}

echo -e "${CYAN}=== Test: Pre-installed Environment ===${RESET}"
echo ""

# Pre-existing files were created in the Dockerfile
echo -e "${CYAN}--- Verifying pre-existing files ---${RESET}"
assert_file_contains "/workspace/CLAUDE.md" "Existing CLAUDE.md"

echo ""
echo -e "${CYAN}--- Running main installer ---${RESET}"

cd /workspace
output=$(SKIP_DEVTOOLS=1 bash /vibestack/install.sh 2>&1) || true
echo "$output"

echo ""
echo -e "${CYAN}--- Checking skip behavior ---${RESET}"

# Pre-existing project files should be skipped
assert_output_contains "$output" "skip.*CLAUDE.md"

# Pre-existing file content should be preserved (not overwritten)
assert_file_contains "/workspace/CLAUDE.md" "Existing CLAUDE.md"

# docs/vibestack.md should be skipped because docs/ has content
assert_output_contains "$output" "skip.*vibestack.md"

# Managed files should still be installed (they didn't exist before)
if [[ -f ".claude/skills/vibestack/SKILL.md" ]]; then
  echo -e "  ${GREEN}PASS${RESET}  Managed files installed despite existing project files"
  ((++pass))
else
  echo -e "  ${RED}FAIL${RESET}  Managed files not installed"
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
