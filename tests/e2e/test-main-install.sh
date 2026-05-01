#!/usr/bin/env bash
# Test the v2 VibeStack installer — user-level install at ~/.claude/
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
    echo -e "  ${GREEN}PASS${RESET}  $1 not present (correct for v2)"
    ((++pass))
  else
    echo -e "  ${RED}FAIL${RESET}  $1 should not exist (v2 doesn't install project-level files)"
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

echo -e "${CYAN}=== Test: VibeStack v2 Installer (user-level) ===${RESET}"
echo ""

mkdir -p /workspace
cd /workspace
SKIP_DEVTOOLS=1 VIBESTACK_REPO="${VIBESTACK_REPO:-file:///vibestack/kit}" bash /vibestack/install.sh || true

USER_DIR="$HOME/.claude"

echo ""
echo -e "${CYAN}--- Skills installed at user level ---${RESET}"

for skill in vibestack todo squad docs bosskey ideate cli-first developer-environment; do
  assert_file_exists "$USER_DIR/skills/$skill/SKILL.md"
done

# lsp must NOT be installed in v2
assert_file_absent "$USER_DIR/skills/lsp"

echo ""
echo -e "${CYAN}--- Skill template files ---${RESET}"

assert_file_exists "$USER_DIR/skills/vibestack/templates/CLAUDE.md"
assert_file_exists "$USER_DIR/skills/vibestack/templates/Makefile"
assert_file_contains "$USER_DIR/skills/vibestack/templates/Makefile" "help"

echo ""
echo -e "${CYAN}--- Hooks installed at user level ---${RESET}"

assert_file_exists "$USER_DIR/hooks/notify-done.sh"
assert_file_executable "$USER_DIR/hooks/notify-done.sh"
assert_file_exists "$USER_DIR/hooks/statusline.sh"
assert_file_executable "$USER_DIR/hooks/statusline.sh"

echo ""
echo -e "${CYAN}--- settings.json ---${RESET}"

assert_file_exists "$USER_DIR/settings.json"
assert_file_contains "$USER_DIR/settings.json" "skipDangerousModePermissionPrompt"
assert_file_contains "$USER_DIR/settings.json" "voiceEnabled"
assert_file_contains "$USER_DIR/settings.json" "enabledPlugins"
assert_file_contains "$USER_DIR/settings.json" "rust-analyzer-lsp"
# Hooks should reference $HOME, not $CLAUDE_PROJECT_DIR
assert_file_contains "$USER_DIR/settings.json" "\$HOME/.claude/hooks/statusline.sh"
if grep -q "CLAUDE_PROJECT_DIR" "$USER_DIR/settings.json" 2>/dev/null; then
  echo -e "  ${RED}FAIL${RESET}  settings.json still references \$CLAUDE_PROJECT_DIR (should be \$HOME at user level)"
  ((++fail))
else
  echo -e "  ${GREEN}PASS${RESET}  settings.json does not reference \$CLAUDE_PROJECT_DIR"
  ((++pass))
fi

echo ""
echo -e "${CYAN}--- Project directory remains untouched ---${RESET}"

# v2 must NOT drop any project-level files
assert_file_absent "/workspace/CLAUDE.md"
assert_file_absent "/workspace/Makefile"
assert_file_absent "/workspace/docs"
assert_file_absent "/workspace/.claude"

echo ""
echo -e "${CYAN}--- Skill content sanity ---${RESET}"

assert_file_contains "$USER_DIR/skills/vibestack/SKILL.md" "CLAUDE_SKILL_DIR"
assert_file_contains "$USER_DIR/skills/vibestack/SKILL.md" "user_invocable: true"
assert_file_contains "$USER_DIR/skills/cli-first/SKILL.md" "cli-first"
assert_file_contains "$USER_DIR/skills/developer-environment/SKILL.md" "developer-environment"

# ── Re-run test (idempotency) ──────────────────────────

echo ""
echo -e "${CYAN}--- Re-run installer (idempotency) ---${RESET}"

output=$(SKIP_DEVTOOLS=1 VIBESTACK_REPO="${VIBESTACK_REPO:-file:///vibestack/kit}" bash /vibestack/install.sh 2>&1) || true
clean_output=$(echo "$output" | sed 's/\x1b\[[0-9;]*m//g')

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
