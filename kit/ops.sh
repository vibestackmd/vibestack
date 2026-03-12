#!/usr/bin/env bash
# ops.sh — project CLI
#
# Single entry point for all project operations: build, run, test, deploy.
# Both humans and AI agents use this as the "how do I do anything" reference.
#
# Usage: ./ops.sh <command> [args]

set -euo pipefail

# ──────────────── Config ────────────────

PROJECT_NAME="myproject"

# ──────────────── Helpers ────────────────

die() { echo "Error: $*" >&2; exit 1; }

# ──────────────── Commands ────────────────

cmd="${1:-help}"
shift || true

# ─── build ──────────────────────────────────────────────

if [[ "$cmd" == "build" ]]; then

    echo "Building $PROJECT_NAME..."
    # cargo build --release
    # npm run build
    # go build -o bin/$PROJECT_NAME ./cmd/$PROJECT_NAME
    echo "TODO: add your build command"

# ─── test ───────────────────────────────────────────────

elif [[ "$cmd" == "test" ]]; then

    echo "Running tests..."
    # cargo test
    # npm test
    # go test ./...
    echo "TODO: add your test command"

# ─── run ────────────────────────────────────────────────

elif [[ "$cmd" == "run" ]]; then

    echo "Running $PROJECT_NAME locally..."
    # cargo run -- "$@"
    # npm run dev
    # go run ./cmd/$PROJECT_NAME "$@"
    echo "TODO: add your run command"

# ─── deploy ─────────────────────────────────────────────

elif [[ "$cmd" == "deploy" ]]; then

    TARGET="${1:-}"
    [[ -n "$TARGET" ]] || die "Usage: ./ops.sh deploy <target>"

    echo "Deploying $PROJECT_NAME to $TARGET..."
    # vercel --prod
    # ssh user@host "cd ~/app && git pull && ./ops.sh build"
    echo "TODO: add your deploy command"

# ─── logs ───────────────────────────────────────────────

elif [[ "$cmd" == "logs" ]]; then

    TARGET="${1:-}"
    [[ -n "$TARGET" ]] || die "Usage: ./ops.sh logs <target>"

    echo "Tailing logs for $TARGET..."
    # ssh user@host "tail -f ~/app/output.log"
    # vercel logs --follow
    echo "TODO: add your logs command"

# ─── status ─────────────────────────────────────────────

elif [[ "$cmd" == "status" ]]; then

    echo "$PROJECT_NAME status..."
    # curl -s https://myapp.com/health | jq .
    # ssh user@host "systemctl status myapp"
    echo "TODO: add your status command"

# ─── docs ───────────────────────────────────────────────

elif [[ "$cmd" == "docs" ]]; then

    PORT="${1:-3000}"
    echo "Serving docs on http://localhost:$PORT ..."
    # mdbook serve docs --port "$PORT" --open
    # cd docs && npx serve -p "$PORT"
    # cd docs && python3 -m http.server "$PORT"
    echo "TODO: add your docs server command"

# ─── help ───────────────────────────────────────────────

elif [[ "$cmd" == "help" ]]; then

    cat << 'EOF'
Usage: ./ops.sh COMMAND [args]

Build & run:
  build                  Build the project
  test                   Run tests
  run                    Run locally

Deploy & manage:
  deploy <target>        Deploy to a target
  logs <target>          Tail logs
  status                 Show project status

Utilities:
  docs [port]            Serve docs locally (default: 3000)

Examples:
  ./ops.sh build
  ./ops.sh test
  ./ops.sh deploy prod
  ./ops.sh logs prod

EOF

else
    die "Unknown command: $cmd (try: ./ops.sh help)"
fi
