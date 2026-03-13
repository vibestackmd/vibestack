#!/usr/bin/env bash
# Build the VibeStack Claude Code plugin from kit/ sources.
#
# Usage:
#   ./scripts/build-plugin.sh          # uses VERSION file
#   ./scripts/build-plugin.sh 0.2.0    # override version

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

SKILLS=(vibestack todo squad docs cli-first lsp)
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

# Rewrite statusLine command path
if "statusLine" in src:
    sl = src["statusLine"].copy()
    if "command" in sl:
        sl["command"] = sl["command"].replace(
            "$CLAUDE_PROJECT_DIR/.claude/hooks/",
            "${CLAUDE_PLUGIN_ROOT}/hooks/"
        )
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
                        hk["command"] = hk["command"].replace(
                            "$CLAUDE_PROJECT_DIR/.claude/hooks/",
                            "${CLAUDE_PLUGIN_ROOT}/hooks/"
                        )
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
    "description": "Opinionated project structure, skills, and tooling for AI-assisted development.",
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

for f in "${EXPECTED_FILES[@]}"; do
  if [[ ! -f "$BUILD_DIR/$f" ]]; then
    echo -e "  ${RED}MISSING: $f${RESET}"
    ERRORS=$((ERRORS + 1))
  fi
done

# Verify no CLAUDE_PROJECT_DIR references leaked into plugin
if grep -r 'CLAUDE_PROJECT_DIR' "$BUILD_DIR/" >/dev/null 2>&1; then
  echo -e "  ${RED}ERROR: Found unrewritten \$CLAUDE_PROJECT_DIR references${RESET}"
  grep -rl 'CLAUDE_PROJECT_DIR' "$BUILD_DIR/"
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
