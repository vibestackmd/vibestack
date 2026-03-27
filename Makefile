VERSION := $(shell tr -d '[:space:]' < VERSION)
MAJOR   := $(word 1,$(subst ., ,$(VERSION)))
MINOR   := $(word 2,$(subst ., ,$(VERSION)))
PATCH   := $(word 3,$(subst ., ,$(VERSION)))

.PHONY: help dev build deploy plugin release-patch release-minor release-major test test-quick test-ubuntu test-wsl clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

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

release-patch: ## Bump patch version, tag, and push
	$(call do-release,$(MAJOR).$(MINOR).$(shell echo $$(($(PATCH)+1))))

release-minor: ## Bump minor version, tag, and push
	$(call do-release,$(MAJOR).$(shell echo $$(($(MINOR)+1))).0)

release-major: ## Bump major version, tag, and push
	$(call do-release,$(shell echo $$(($(MAJOR)+1))).0.0)

define do-release
	@echo ""
	@# ── Preflight checks ───────────────────────────────────
	@branch=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$branch" != "main" ]; then \
		echo "  \033[31mError: must be on main (currently on $$branch)\033[0m"; exit 1; \
	fi
	@if ! git diff --quiet || ! git diff --cached --quiet; then \
		echo "  \033[31mError: working tree is dirty — commit or stash first\033[0m"; exit 1; \
	fi
	@git fetch origin main --quiet; \
	if [ "$$(git rev-parse HEAD)" != "$$(git rev-parse origin/main)" ]; then \
		echo "  \033[31mError: local main is out of sync with origin — pull first\033[0m"; exit 1; \
	fi
	@if git tag -l "v$(1)" | grep -q .; then \
		echo "  \033[31mError: tag v$(1) already exists\033[0m"; exit 1; \
	fi
	@# ── Confirm and release ────────────────────────────────
	@echo "  $(VERSION) → $(1)"
	@echo ""
	@read -p "  Release v$(1)? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@echo "  Running E2E tests before release..."
	@chmod +x tests/e2e/run.sh && ./tests/e2e/run.sh preinstalled
	@echo ""
	@echo "$(1)" > VERSION
	@git add VERSION
	@git commit -m "release v$(1)"
	@./scripts/build-plugin.sh $(1)
	@git tag v$(1)
	@git push origin main v$(1)
	@echo ""
	@echo "  \033[32mPushed v$(1) — GitHub Actions will create the release.\033[0m"
endef

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
