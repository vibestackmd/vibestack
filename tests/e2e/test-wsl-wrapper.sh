#!/usr/bin/env bash
# Wrapper that sets up the fake /proc/version for WSL simulation,
# then hands off to the real test script.
set -euo pipefail

# The Dockerfile.wsl created /wsl-proc-version with "microsoft" in it.
# Mount it over /proc/version so the installers detect WSL.
if [[ -f /wsl-proc-version ]]; then
  mount --bind /wsl-proc-version /proc/version
fi

exec bash /vibestack/tests/e2e/test-wsl.sh
