VERSION := $(shell tr -d '[:space:]' < VERSION)

.PHONY: help dev build deploy plugin release test test-quick test-ubuntu test-wsl clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

# ── Site ─────────────────────────────────────────────────

dev: ## Run site dev server
	cd site && npm run dev

build: ## Build site for production
	cd site && npm run build

deploy: build ## Build and deploy site to Vercel
	cd site && vercel --prod --yes

# ── Plugin ───────────────────────────────────────────────

plugin: ## Build Claude Code plugin to dist/
	@./scripts/build-plugin.sh $(VERSION)

release: plugin ## Tag and push a release (triggers GitHub Actions)
	@echo ""
	@echo "  Version: v$(VERSION)"
	@echo ""
	@read -p "  Tag v$(VERSION) and push? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	git tag v$(VERSION)
	git push origin v$(VERSION)
	@echo ""
	@echo "  \033[32mPushed v$(VERSION) — GitHub Actions will create the release.\033[0m"

# ── Tests ────────────────────────────────────────────────

test: test-quick ## Run tests (alias for test-quick)

test-quick: ## Run quick E2E tests (main installer + skip behavior)
	chmod +x tests/e2e/run.sh && ./tests/e2e/run.sh preinstalled

test-ubuntu: ## Run full Ubuntu install test (Docker)
	chmod +x tests/e2e/run.sh && ./tests/e2e/run.sh ubuntu

test-wsl: ## Run WSL simulation test (Docker)
	chmod +x tests/e2e/run.sh && ./tests/e2e/run.sh wsl

# ── Misc ─────────────────────────────────────────────────

clean: ## Remove build artifacts
	rm -rf dist site/.next site/out
