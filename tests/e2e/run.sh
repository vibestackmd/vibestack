#!/usr/bin/env bash
#
# VibeStack E2E Test Runner
#
# Builds Docker images, runs tests in containers, destroys everything after.
# All containers are ephemeral — nothing persists after the run.
#
# Usage:
#   ./tests/e2e/run.sh              # Run all tests
#   ./tests/e2e/run.sh ubuntu       # Run a single suite
#   ./tests/e2e/run.sh --quick      # Run only fast tests (main installer only)
#
# Suites: ubuntu, wsl, preinstalled
#
# The "ubuntu" suite runs both the main installer and dev-tools installer
# (installs real tools — takes ~5 min). Other suites are faster.
#
# Requires: Docker

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

CYAN="\033[0;36m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BOLD="\033[1m"
RESET="\033[0m"

# ── Preflight ───────────────────────────────────────────

if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}Docker is required but not installed.${RESET}"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo -e "${RED}Docker daemon is not running.${RESET}"
  exit 1
fi

# ── Parse args ──────────────────────────────────────────

QUICK=false
SUITES=()

for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=true ;;
    *) SUITES+=("$arg") ;;
  esac
done

# Default: run all suites
if [[ ${#SUITES[@]} -eq 0 ]]; then
  if $QUICK; then
    SUITES=("preinstalled")
  else
    SUITES=("ubuntu" "wsl" "preinstalled")
  fi
fi

# ── Helpers ─────────────────────────────────────────────

IMAGE_PREFIX="vibestack-e2e"
total_pass=0
total_fail=0
suite_results=()

cleanup() {
  echo ""
  echo -e "${CYAN}Cleaning up Docker images...${RESET}"
  docker images --filter "reference=${IMAGE_PREFIX}-*" -q 2>/dev/null | xargs -r docker rmi -f 2>/dev/null || true
  # Also clean any dangling images from failed builds
  docker image prune -f 2>/dev/null || true
  echo -e "${GREEN}Clean.${RESET}"
}
trap cleanup EXIT

build_image() {
  local name="$1"
  local dockerfile="$2"
  echo -e "${CYAN}Building ${name}...${RESET}"
  docker build -t "${IMAGE_PREFIX}-${name}" -f "$dockerfile" "$SCRIPT_DIR" --quiet
}

run_test() {
  local name="$1"
  local docker_image="$2"
  local test_script="$3"
  shift 3
  local extra_args=("$@")

  echo ""
  echo -e "${CYAN}${BOLD}━━━ Suite: ${name} ━━━${RESET}"
  echo ""

  if docker run --rm \
    -e NONINTERACTIVE=1 \
    -v "${REPO_DIR}:/vibestack:ro" \
    ${extra_args[@]+"${extra_args[@]}"} \
    "${IMAGE_PREFIX}-${docker_image}" \
    bash "/vibestack/tests/e2e/${test_script}"; then
    suite_results+=("${GREEN}PASS${RESET}  ${name}")
    return 0
  else
    suite_results+=("${RED}FAIL${RESET}  ${name}")
    ((++total_fail))
    return 1
  fi
}

# ── Build images ────────────────────────────────────────

echo -e "${CYAN}${BOLD}VibeStack E2E Tests${RESET}"
echo ""

images_needed=()
for suite in "${SUITES[@]}"; do
  case "$suite" in
    ubuntu) images_needed+=("ubuntu") ;;
    wsl) images_needed+=("wsl") ;;
    preinstalled) images_needed+=("preinstalled") ;;
    *)
      echo -e "${RED}Unknown suite: $suite${RESET}"
      echo "Available: ubuntu, wsl, preinstalled"
      exit 1
      ;;
  esac
done

# Deduplicate and build
declare -A built
for img in "${images_needed[@]}"; do
  if [[ -z "${built[$img]:-}" ]]; then
    build_image "$img" "$SCRIPT_DIR/Dockerfile.$img"
    built[$img]=1
  fi
done

# ── Run suites ──────────────────────────────────────────

for suite in "${SUITES[@]}"; do
  case "$suite" in
    ubuntu)
      # Full test: main installer + dev-tools (slow, installs real tools)
      run_test "ubuntu-main" "ubuntu" "test-main-install.sh" || true
      if ! $QUICK; then
        run_test "ubuntu-devtools" "ubuntu" "test-dev-tools.sh" || true
      fi
      ;;
    wsl)
      # WSL simulation — runs privileged so we can bind-mount over /proc/version
      run_test "wsl" "wsl" "test-wsl-wrapper.sh" --privileged || true
      ;;
    preinstalled)
      # Pre-installed tools — tests skip/idempotency behavior
      run_test "preinstalled" "preinstalled" "test-preinstalled.sh" || true
      ;;
  esac
done

# ── Summary ─────────────────────────────────────────────

echo ""
echo -e "${CYAN}${BOLD}━━━ Results ━━━${RESET}"
echo ""
for result in "${suite_results[@]}"; do
  echo -e "  $result"
done
echo ""

if [[ $total_fail -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}All suites passed.${RESET}"
  exit 0
else
  echo -e "${RED}${BOLD}$total_fail suite(s) failed.${RESET}"
  exit 1
fi
