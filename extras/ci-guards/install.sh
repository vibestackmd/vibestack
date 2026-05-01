#!/usr/bin/env bash
set -euo pipefail

REPO="vibestackmd/vibestack"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/kit/extras/ci-guards/examples"
DEST=".github/workflows/ci.yml"

LANGUAGES="node python rust go"

usage() {
  echo "Usage: curl -fsSL https://raw.githubusercontent.com/${REPO}/${BRANCH}/kit/extras/ci-guards/install.sh | bash -s -- <language>"
  echo ""
  echo "Languages: ${LANGUAGES}"
  echo ""
  echo "Options:"
  echo "  -o, --output PATH   Write to a custom path (default: ${DEST})"
  echo "  -h, --help          Show this help"
  exit 1
}

LANG=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) OUTPUT="$2"; shift 2 ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $1"; usage ;;
    *) LANG="$1"; shift ;;
  esac
done

if [[ -z "${LANG}" ]]; then
  echo "Error: language is required"
  echo ""
  usage
fi

# Normalize language name
LANG=$(echo "${LANG}" | tr '[:upper:]' '[:lower:]')
case "${LANG}" in
  node|nodejs|ts|typescript) LANG="node" ;;
  python|py) LANG="python" ;;
  rust|rs) LANG="rust" ;;
  go|golang) LANG="go" ;;
  *) echo "Error: unsupported language '${LANG}'"; echo "Supported: ${LANGUAGES}"; exit 1 ;;
esac

DEST="${OUTPUT:-${DEST}}"
SOURCE_URL="${BASE_URL}/${LANG}-caller.yml"

mkdir -p "$(dirname "${DEST}")"

if [[ -f "${DEST}" ]]; then
  echo "Warning: ${DEST} already exists."
  if [[ -t 0 ]]; then
    read -rp "Overwrite? [y/N] " confirm
  else
    # When piped (curl | bash), read from terminal directly
    read -rp "Overwrite? [y/N] " confirm < /dev/tty || confirm="n"
  fi
  if [[ "${confirm}" != [yY] ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "Downloading ${LANG} CI workflow..."
curl -fsSL "${SOURCE_URL}" -o "${DEST}"

echo ""
echo "Installed to ${DEST}"
echo ""
echo "Next steps:"
echo "  1. Push and open a PR to see it in action"
echo "  2. (Optional) Add ANTHROPIC_API_KEY to your repo secrets (Settings > Secrets)"
echo "     This enables AI-powered teaching feedback on failed PRs."
