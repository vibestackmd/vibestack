# Makefile — project operations
#
# Single entry point for all project operations: build, run, test, deploy.
# Both humans and AI agents use this as the "how do I do anything" reference.
#
# Usage: make <target>
#
# Convention: keep targets simple. If a target needs more than a few lines of
# shell, put the logic in scripts/ and call it from here.

.PHONY: build test run deploy logs status docs help

PROJECT_NAME := myproject

# ── Build & Run ───────────────────────────────────────────

build: ## Build the project
	@echo "Building $(PROJECT_NAME)..."
	# npm run build
	# cargo build --release
	# go build -o bin/$(PROJECT_NAME) ./cmd/$(PROJECT_NAME)
	@echo "TODO: add your build command"

test: ## Run tests
	@echo "Running tests..."
	# npm test
	# cargo test
	# go test ./...
	@echo "TODO: add your test command"

run: ## Run locally
	@echo "Running $(PROJECT_NAME) locally..."
	# npm run dev
	# cargo run
	# go run ./cmd/$(PROJECT_NAME)
	@echo "TODO: add your run command"

# ── Deploy & Manage ───────────────────────────────────────

deploy: ## Deploy to a target (usage: make deploy TARGET=prod)
	@test -n "$(TARGET)" || (echo "Usage: make deploy TARGET=<target>" && exit 1)
	@echo "Deploying $(PROJECT_NAME) to $(TARGET)..."
	# vercel --prod
	# bash scripts/deploy.sh $(TARGET)
	@echo "TODO: add your deploy command"

logs: ## Tail logs (usage: make logs TARGET=prod)
	@test -n "$(TARGET)" || (echo "Usage: make logs TARGET=<target>" && exit 1)
	@echo "Tailing logs for $(TARGET)..."
	# vercel logs --follow
	# bash scripts/logs.sh $(TARGET)
	@echo "TODO: add your logs command"

status: ## Show project status
	@echo "$(PROJECT_NAME) status..."
	# curl -s https://myapp.com/health | jq .
	@echo "TODO: add your status command"

# ── Utilities ─────────────────────────────────────────────

docs: ## Serve docs locally (usage: make docs PORT=3000)
	@echo "Serving docs on http://localhost:$${PORT:-3000} ..."
	# mdbook serve docs --port $${PORT:-3000} --open
	# cd docs && npx serve -p $${PORT:-3000}
	@echo "TODO: add your docs server command"

# ── Help ──────────────────────────────────────────────────

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
