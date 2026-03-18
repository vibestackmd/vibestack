#!/usr/bin/env bash
# Test the main VibeStack installer (project convention files)
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

assert_file_contains() {
  if grep -q "$2" "$1" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${RESET}  $1 contains '$2'"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $1 does not contain '$2'"
    ((++fail))
  fi
}

assert_file_executable() {
  if [[ -x "$1" ]]; then
    echo -e "  ${GREEN}PASS${RESET}  $1 is executable"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $1 is not executable"
    ((++fail))
  fi
}

echo -e "${CYAN}=== Test: Main VibeStack Installer ===${RESET}"
echo ""

# Run the installer (skip dev-tools to keep output clean and test focused)
cd /workspace
SKIP_DEVTOOLS=1 bash /vibestack/install.sh || true

echo ""
echo -e "${CYAN}--- Checking project files ---${RESET}"

# Project convention files
assert_file_exists "CLAUDE.md"
assert_file_exists "TODO.md"
assert_file_exists "Makefile"
assert_file_exists "docs/vibestack.md"

# Makefile should contain help target
assert_file_contains "Makefile" "help"

echo ""
echo -e "${CYAN}--- Checking managed files ---${RESET}"

# Skills
assert_file_exists ".claude/skills/vibestack/SKILL.md"
assert_file_exists ".claude/skills/cli-first/SKILL.md"
assert_file_exists ".claude/skills/docs/SKILL.md"
assert_file_exists ".claude/skills/squad/SKILL.md"

# Hook
assert_file_exists ".claude/hooks/notify-done.sh"
assert_file_executable ".claude/hooks/notify-done.sh"

echo ""
echo -e "${CYAN}--- Checking settings merge ---${RESET}"

# Settings should exist and contain key vibestack config
assert_file_exists ".claude/settings.json"
assert_file_contains ".claude/settings.json" "Bash"
assert_file_contains ".claude/settings.json" "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"

echo ""
echo -e "${CYAN}--- Checking skill content ---${RESET}"

assert_file_contains ".claude/skills/squad/SKILL.md" "squad"
assert_file_contains ".claude/skills/squad/SKILL.md" "user_invocable: true"
assert_file_contains ".claude/skills/vibestack/SKILL.md" "vibestack"
assert_file_contains ".claude/skills/cli-first/SKILL.md" "cli-first"

echo ""
echo -e "${CYAN}--- Checking CLAUDE.md template ---${RESET}"

assert_file_contains "CLAUDE.md" "Makefile"
assert_file_contains "CLAUDE.md" "/squad"

# ── Re-run test (idempotency) ──────────────────────────

echo ""
echo -e "${CYAN}--- Re-run installer (idempotency) ---${RESET}"

# Run again — should skip existing project files, report managed files as ok
output=$(SKIP_DEVTOOLS=1 bash /vibestack/install.sh 2>&1) || true

clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')

if echo "$clean_output" | grep -qE "skip.*CLAUDE.md"; then
  echo -e "  ${GREEN}PASS${RESET}  Re-run skips existing CLAUDE.md"
  ((++pass))
else
  echo -e "  ${RED}FAIL${RESET}  Re-run did not skip existing CLAUDE.md"
  ((++fail))
fi

if echo "$clean_output" | grep -qE "ok|up to date"; then
  echo -e "  ${GREEN}PASS${RESET}  Re-run reports managed files up to date"
  ((++pass))
else
  echo -e "  ${RED}FAIL${RESET}  Re-run did not report managed files as up to date"
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
