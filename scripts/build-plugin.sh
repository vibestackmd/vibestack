#!/usr/bin/env bash
# Build the VibeStack Claude Code plugin from kit/ sources.
#
# Usage:
#   make plugin
#   ./build-plugin.sh 0.2.0    # override version

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(cat "$REPO_ROOT/VERSION" | tr -d '[:space:]')}"
BUILD_DIR="$REPO_ROOT/dist/plugin"

CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${CYAN}Building VibeStack plugin v${VERSION}${RESET}"
echo ""

# ── Clean ────────────────────────────────────────────────
rm -rf "$BUILD_DIR"

# ── Create structure ─────────────────────────────────────
mkdir -p "$BUILD_DIR/.claude-plugin"
mkdir -p "$BUILD_DIR/hooks"

SKILLS=(vibestack todo squad docs bosskey ideate cli-first developer-environment)
for skill in "${SKILLS[@]}"; do
  mkdir -p "$BUILD_DIR/skills/$skill"
done

# ── Copy skills ──────────────────────────────────────────
for skill in "${SKILLS[@]}"; do
  src="$REPO_ROOT/kit/.claude/skills/$skill/SKILL.md"
  if [[ ! -f "$src" ]]; then
    echo -e "${RED}Missing skill: $src${RESET}"
    exit 1
  fi
  cp "$src" "$BUILD_DIR/skills/$skill/SKILL.md"
done

# Copy any sibling assets (e.g. templates/) that ship inside skill folders
if [[ -d "$REPO_ROOT/kit/.claude/skills/vibestack/templates" ]]; then
  cp -R "$REPO_ROOT/kit/.claude/skills/vibestack/templates" "$BUILD_DIR/skills/vibestack/"
fi

echo "  Skills: ${SKILLS[*]}"

# ── Copy hooks ───────────────────────────────────────────
cp "$REPO_ROOT/kit/.claude/hooks/notify-done.sh" "$BUILD_DIR/hooks/"
cp "$REPO_ROOT/kit/.claude/hooks/statusline.sh" "$BUILD_DIR/hooks/"
chmod +x "$BUILD_DIR/hooks/"*.sh
echo "  Hooks:  notify-done.sh, statusline.sh"

# ── Build settings.json (hooks + statusLine only, rewrite paths) ──
/usr/bin/python3 << 'PYEOF' - "$REPO_ROOT/kit/.claude/settings.json" "$BUILD_DIR/settings.json"
import json, sys

src_path, dest_path = sys.argv[1], sys.argv[2]

with open(src_path) as f:
    src = json.load(f)

plugin = {}

def rewrite_path(cmd: str) -> str:
    # Rewrite both legacy ($CLAUDE_PROJECT_DIR) and v2 ($HOME) hook paths
    # to the plugin-relative path so the plugin works once installed.
    return (cmd
            .replace("$CLAUDE_PROJECT_DIR/.claude/hooks/", "${CLAUDE_PLUGIN_ROOT}/hooks/")
            .replace("$HOME/.claude/hooks/", "${CLAUDE_PLUGIN_ROOT}/hooks/"))

# Rewrite statusLine command path
if "statusLine" in src:
    sl = src["statusLine"].copy()
    if "command" in sl:
        sl["command"] = rewrite_path(sl["command"])
    plugin["statusLine"] = sl

# Rewrite hook command paths
if "hooks" in src:
    hooks = {}
    for event, handlers in src["hooks"].items():
        rewritten = []
        for handler in handlers:
            h = handler.copy()
            if "hooks" in h:
                new_hooks = []
                for hook in h["hooks"]:
                    hk = hook.copy()
                    if "command" in hk:
                        hk["command"] = rewrite_path(hk["command"])
                    new_hooks.append(hk)
                h["hooks"] = new_hooks
            rewritten.append(h)
        hooks[event] = rewritten
    plugin["hooks"] = hooks

with open(dest_path, "w") as f:
    json.dump(plugin, f, indent=2)
    f.write("\n")
PYEOF
echo "  Settings: statusLine + hooks (permissions excluded — project-level concern)"

# ── Generate plugin.json manifest ────────────────────────
/usr/bin/python3 << PYEOF - "$BUILD_DIR/.claude-plugin/plugin.json" "$VERSION"
import json, sys

dest_path, version = sys.argv[1], sys.argv[2]

manifest = {
    "name": "vibestack",
    "version": version,
    "description": "Opinionated user-level skills, hooks, and settings for AI-assisted development.",
    "author": "vibestackmd",
    "repository": "https://github.com/vibestackmd/vibestack"
}

with open(dest_path, "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
PYEOF
echo "  Manifest: .claude-plugin/plugin.json"

# ── Validate ─────────────────────────────────────────────
echo ""
echo "Validating..."

ERRORS=0

EXPECTED_FILES=(
  ".claude-plugin/plugin.json"
  "settings.json"
  "hooks/notify-done.sh"
  "hooks/statusline.sh"
)
for skill in "${SKILLS[@]}"; do
  EXPECTED_FILES+=("skills/$skill/SKILL.md")
done

# vibestack ships starter templates inside its skill folder
EXPECTED_FILES+=(
  "skills/vibestack/templates/CLAUDE.md"
  "skills/vibestack/templates/Makefile"
)

for f in "${EXPECTED_FILES[@]}"; do
  if [[ ! -f "$BUILD_DIR/$f" ]]; then
    echo -e "  ${RED}MISSING: $f${RESET}"
    ERRORS=$((ERRORS + 1))
  fi
done

# Verify no unrewritten host paths leaked into the plugin's settings.json
if grep -E '\$CLAUDE_PROJECT_DIR|\$HOME/\.claude/hooks/' "$BUILD_DIR/settings.json" >/dev/null 2>&1; then
  echo -e "  ${RED}ERROR: Found unrewritten host path references in settings.json${RESET}"
  grep -nE '\$CLAUDE_PROJECT_DIR|\$HOME/\.claude/hooks/' "$BUILD_DIR/settings.json"
  ERRORS=$((ERRORS + 1))
fi

# Verify plugin.json version matches
MANIFEST_VERSION=$(/usr/bin/python3 -c "import json; print(json.load(open('$BUILD_DIR/.claude-plugin/plugin.json'))['version'])")
if [[ "$MANIFEST_VERSION" != "$VERSION" ]]; then
  echo -e "  ${RED}ERROR: Manifest version ($MANIFEST_VERSION) != expected ($VERSION)${RESET}"
  ERRORS=$((ERRORS + 1))
fi

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo -e "${RED}Validation failed with $ERRORS error(s).${RESET}"
  exit 1
fi

echo -e "  ${GREEN}All checks passed.${RESET}"

# ── Package tarball ──────────────────────────────────────
TARBALL="$REPO_ROOT/dist/vibestack-plugin-${VERSION}.tar.gz"
tar -czf "$TARBALL" -C "$REPO_ROOT/dist" plugin/

echo ""
echo -e "${GREEN}Plugin built successfully.${RESET}"
echo "  Directory: $BUILD_DIR"
echo "  Tarball:   $TARBALL"
echo "  Version:   $VERSION"
