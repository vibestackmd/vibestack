#!/usr/bin/env bash
#
# Skill validation. Runs locally (no Docker, no API key) as part of `make plugin`.
#
# Checks:
#   1. Every skills/*/SKILL.md has frontmatter with `name:` and `description:`,
#      and `name:` matches the directory.
#   2. The /cicd skill's embedded GitHub Actions YAML snippets are structurally
#      sound: no tab indentation, every job has `runs-on:` and `steps:`, and the
#      four supported language jobs (node, python, go, rust) are all present.
#
# This is the deterministic half of "test the /cicd skill". The other half,
# actually invoking Claude and checking the generated ci.yml, needs an API key
# and lives outside CI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_DIR="$REPO_ROOT/skills"

GREEN="\033[0;32m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

pass=0
fail=0

ok() { echo -e "  ${GREEN}PASS${RESET}  $1"; ((++pass)); }
no() { echo -e "  ${RED}FAIL${RESET}  $1"; ((++fail)); }

echo -e "${CYAN}=== Skill validation ===${RESET}"
echo ""

# ── 1. Frontmatter check for every skill ────────────────
echo -e "${CYAN}--- Frontmatter ---${RESET}"
for skill_md in "$SKILLS_DIR"/*/SKILL.md; do
  skill_dir=$(basename "$(dirname "$skill_md")")
  fm_name=$(grep -m1 '^name:' "$skill_md" 2>/dev/null | sed 's/^name:[[:space:]]*//' || true)
  fm_desc=$(grep -m1 '^description:' "$skill_md" 2>/dev/null || true)

  if [[ -z "$fm_name" ]]; then
    no "$skill_dir: missing 'name:' in frontmatter"
  elif [[ "$fm_name" != "$skill_dir" ]]; then
    no "$skill_dir: frontmatter name '$fm_name' does not match directory"
  else
    ok "$skill_dir: name matches directory"
  fi

  if [[ -z "$fm_desc" ]]; then
    no "$skill_dir: missing 'description:' in frontmatter"
  fi
done

# ── 2. /cicd YAML snippet structural check ──────────────
echo ""
echo -e "${CYAN}--- /cicd workflow snippets ---${RESET}"

CICD_MD="$SKILLS_DIR/cicd/SKILL.md"
if [[ ! -f "$CICD_MD" ]]; then
  no "/cicd skill missing at $CICD_MD"
else
  # Extract every fenced ```yaml block into one buffer.
  yaml_blocks=$(awk '/^```yaml$/{flag=1;next}/^```$/{flag=0}flag' "$CICD_MD")

  if [[ -z "$yaml_blocks" ]]; then
    no "/cicd: no \`\`\`yaml blocks found"
  else
    # YAML forbids tab indentation. A tab in a snippet means a broken workflow.
    # Use a literal tab so this works on both BSD (macOS) and GNU grep.
    if printf '%s\n' "$yaml_blocks" | grep -q "$(printf '\t')"; then
      no "/cicd: YAML snippet contains a tab character (YAML forbids tab indentation)"
    else
      ok "/cicd: no tab indentation in YAML snippets"
    fi

    # The common header must wire up triggers and a jobs map.
    if grep -qE '^on:' <<<"$yaml_blocks" && grep -qE '^jobs:' <<<"$yaml_blocks"; then
      ok "/cicd: common header has 'on:' and 'jobs:'"
    else
      no "/cicd: common header missing 'on:' or 'jobs:'"
    fi

    # Every language job must declare a runner and steps.
    runs_on_count=$(grep -cE '^\s+runs-on:' <<<"$yaml_blocks" || true)
    steps_count=$(grep -cE '^\s+steps:' <<<"$yaml_blocks" || true)
    if [[ "$runs_on_count" -ge 4 && "$steps_count" -ge 4 ]]; then
      ok "/cicd: all job snippets declare 'runs-on:' and 'steps:' ($runs_on_count jobs)"
    else
      no "/cicd: expected >=4 jobs with runs-on/steps, found runs-on=$runs_on_count steps=$steps_count"
    fi

    # The four supported languages must each have a job.
    for lang in node python go rust; do
      if grep -qE "^  $lang:" <<<"$yaml_blocks"; then
        ok "/cicd: '$lang' job snippet present"
      else
        no "/cicd: '$lang' job snippet missing"
      fi
    done
  fi
fi

# ── Summary ─────────────────────────────────────────────
echo ""
echo -e "${CYAN}==============================${RESET}"
if [[ $fail -eq 0 ]]; then
  echo -e "${GREEN}All $pass skill checks passed.${RESET}"
else
  echo -e "${RED}$fail failed${RESET}, ${GREEN}$pass passed${RESET}"
fi
echo ""

exit $fail
