#!/usr/bin/env bash
# Build VibeStack plugin artifacts from the in-tree plugin sources.
#
# Under the v3 layout, the repo root IS the plugin root — `.claude-plugin/`,
# `skills/`, `hooks/`, and `settings.json` live at root. Production installs
# pull directly from the repo via `claude plugin marketplace add vibestackmd/vibestack`,
# so this script's only jobs are:
#   1. Sync VERSION → .claude-plugin/{plugin,marketplace}.json (in-tree, committed)
#   2. Validate the plugin tree against the marketplace schema
#   3. Build a tarball release asset (for users who want offline install)
#   4. Build dist/test-marketplace/ for the e2e test runner
#
# Usage:
#   make plugin
#   ./build-plugin.sh 0.2.0    # override version

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(cat "$REPO_ROOT/VERSION" | tr -d '[:space:]')}"

CYAN="\033[0;36m"
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${CYAN}Building VibeStack plugin v${VERSION}${RESET}"
echo ""

# ── Sync versions in committed manifests ─────────────────
# plugin.json + marketplace.json are committed in-tree, so this just rewrites
# the version field to match VERSION. `make release-*` calls this before tagging.
/usr/bin/python3 << PYEOF - "$REPO_ROOT/.claude-plugin/plugin.json" "$VERSION"
import json, sys
path, version = sys.argv[1], sys.argv[2]
with open(path) as f:
    manifest = json.load(f)
manifest["version"] = version
with open(path, "w") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
PYEOF

/usr/bin/python3 << PYEOF - "$REPO_ROOT/.claude-plugin/marketplace.json" "$VERSION"
import json, sys
path, version = sys.argv[1], sys.argv[2]
with open(path) as f:
    market = json.load(f)
for p in market.get("plugins", []):
    if p.get("name") == "vibestack":
        p["version"] = version
with open(path, "w") as f:
    json.dump(market, f, indent=2)
    f.write("\n")
PYEOF
echo "  Versions synced: .claude-plugin/{plugin,marketplace}.json → ${VERSION}"

# ── Validate ─────────────────────────────────────────────
echo ""
echo "Validating..."

ERRORS=0

REQUIRED_FILES=(
  ".claude-plugin/plugin.json"
  ".claude-plugin/marketplace.json"
  "settings.json"
  "hooks/notify-done.sh"
  "hooks/statusline.sh"
)

SKILLS=(vibestack todo squad docs bosskey ideate cli-first developer-environment lsp)
for skill in "${SKILLS[@]}"; do
  REQUIRED_FILES+=("skills/$skill/SKILL.md")
done

# vibestack ships starter templates inside its skill folder
REQUIRED_FILES+=(
  "skills/vibestack/templates/CLAUDE.md"
  "skills/vibestack/templates/Makefile"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [[ ! -f "$REPO_ROOT/$f" ]]; then
    echo -e "  ${RED}MISSING: $f${RESET}"
    ERRORS=$((ERRORS + 1))
  fi
done

# Plugin's settings.json must reference ${CLAUDE_PLUGIN_ROOT}, never host paths.
if grep -E '\$CLAUDE_PROJECT_DIR|\$HOME/\.claude/hooks/' "$REPO_ROOT/settings.json" >/dev/null 2>&1; then
  echo -e "  ${RED}ERROR: settings.json references host paths (should be \${CLAUDE_PLUGIN_ROOT})${RESET}"
  grep -nE '\$CLAUDE_PROJECT_DIR|\$HOME/\.claude/hooks/' "$REPO_ROOT/settings.json"
  ERRORS=$((ERRORS + 1))
fi

# Manifest version must match
MANIFEST_VERSION=$(/usr/bin/python3 -c "import json; print(json.load(open('$REPO_ROOT/.claude-plugin/plugin.json'))['version'])")
if [[ "$MANIFEST_VERSION" != "$VERSION" ]]; then
  echo -e "  ${RED}ERROR: plugin.json version ($MANIFEST_VERSION) != expected ($VERSION)${RESET}"
  ERRORS=$((ERRORS + 1))
fi

if [[ $ERRORS -gt 0 ]]; then
  echo ""
  echo -e "${RED}Validation failed with $ERRORS error(s).${RESET}"
  exit 1
fi

echo -e "  ${GREEN}All checks passed.${RESET}"

# ── Build tarball release asset ──────────────────────────
# Mirrors the plugin layout (root → tarball top-level dir). Users who want an
# offline install can extract this anywhere claude can read it.
BUILD_DIR="$REPO_ROOT/dist/plugin"
TARBALL="$REPO_ROOT/dist/vibestack-plugin-${VERSION}.tar.gz"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cp -R "$REPO_ROOT/.claude-plugin" "$BUILD_DIR/"
cp -R "$REPO_ROOT/skills" "$BUILD_DIR/"
cp -R "$REPO_ROOT/hooks" "$BUILD_DIR/"
cp "$REPO_ROOT/settings.json" "$BUILD_DIR/"

# Tarball doesn't need marketplace.json (it's a plugin tarball, not a marketplace).
rm -f "$BUILD_DIR/.claude-plugin/marketplace.json"

tar -czf "$TARBALL" -C "$REPO_ROOT/dist" plugin/
echo "  Tarball: $TARBALL"

# ── Build local test marketplace ─────────────────────────
# A self-contained marketplace pointing at the plugin via a local-path source.
# E2E tests run `claude plugin marketplace add /path/to/dist/test-marketplace`
# so we can validate the about-to-ship plugin (not the previously-published
# version) end-to-end without needing GitHub.
TEST_MARKET="$REPO_ROOT/dist/test-marketplace"
rm -rf "$TEST_MARKET"
mkdir -p "$TEST_MARKET/.claude-plugin"
mkdir -p "$TEST_MARKET/plugins/vibestack"

cp -R "$BUILD_DIR/.claude-plugin/plugin.json" "$TEST_MARKET/plugins/vibestack/.claude-plugin/" 2>/dev/null || {
  mkdir -p "$TEST_MARKET/plugins/vibestack/.claude-plugin"
  cp "$BUILD_DIR/.claude-plugin/plugin.json" "$TEST_MARKET/plugins/vibestack/.claude-plugin/"
}
cp -R "$BUILD_DIR/skills" "$TEST_MARKET/plugins/vibestack/"
cp -R "$BUILD_DIR/hooks" "$TEST_MARKET/plugins/vibestack/"
cp "$BUILD_DIR/settings.json" "$TEST_MARKET/plugins/vibestack/"

/usr/bin/python3 << PYEOF - "$TEST_MARKET/.claude-plugin/marketplace.json" "$VERSION"
import json, sys
dest_path, version = sys.argv[1], sys.argv[2]
marketplace = {
    "name": "vibestackmd-vibestack",
    "owner": {"name": "vibestackmd"},
    "description": "Opinionated user-level skills, hooks, and settings for AI-assisted development.",
    "plugins": [
        {
            "name": "vibestack",
            "source": "./plugins/vibestack",
            "version": version,
            "description": "Opinionated user-level skills, hooks, and settings for AI-assisted development."
        }
    ],
    "allowCrossMarketplaceDependenciesOn": ["claude-plugins-official"]
}
with open(dest_path, "w") as f:
    json.dump(marketplace, f, indent=2)
    f.write("\n")
PYEOF
echo "  Test marketplace: $TEST_MARKET"

echo ""
echo -e "${GREEN}Plugin built successfully.${RESET}"
echo "  Plugin root:   $REPO_ROOT  (in-tree, served by ./.claude-plugin/marketplace.json)"
echo "  Tarball:       $TARBALL"
echo "  Test market:   $TEST_MARKET"
echo "  Version:       $VERSION"
