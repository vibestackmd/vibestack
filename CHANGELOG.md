# Changelog

All notable changes to VibeStack. Versions follow the `VERSION` file, which is the single source of truth; releases are cut with `make release-*`.

## v1.0.12

Polish pass. Fixed the broken `kit/extras/` install URLs in the dev-tools README and bootstrap script (same v3-restructure breakage caught earlier in ci-guards). Added this `CHANGELOG.md`. Expanded `/prose` to cover secondary AI tells beyond em dashes: inflated verbs ("delve", "leverage"), boilerplate scaffolding, and structural tics. Added `tests/validate-skills.sh`, a Docker-free skill lint that checks frontmatter and validates the `/cicd` skill's embedded workflow YAML; it runs inside `make plugin`. Deleted the orphaned `v1.0.7` tag left behind by that release's CI failure.

## v1.0.11

Comprehensive em-dash sweep. The first pass in v1.0.10 only walked `.md`, `.sh`, and `.json` files; this pass catches `Makefile`, `Dockerfile.*`, `.yml` workflows, `.tsx`, and `.ps1`. Zero em dashes remain anywhere in the repo outside `skills/prose/SKILL.md`, where they appear as quoted examples of the forbidden character.

## v1.0.10

Added the `/prose` skill: an always-loaded writing-style rule (`user-invocable: false`, same mechanism as `/cli-first`) that strictly forbids em dashes and en dashes as punctuation. Em dashes are the single most reliable tell that text was produced by an LLM. Hyphens in compound words and em/en dashes inside proper nouns remain allowed. Stripped all existing em dashes from the repo as part of the same release.

## v1.0.9

Added the `/cicd` skill and retired `extras/ci-guards/`. The old CI setup was a `curl | bash` installer that dropped caller-workflow templates pointing at a shared-workflow repo; its install URL also 404'd after the v3 restructure renamed `kit/extras` to `extras`. The replacement is a self-contained skill that detects the project's language stack and generates `.github/workflows/ci.yml` inline, with no external workflow dependency. `/vibestack` now ends by advertising sibling initial-setup skills (`/cicd`, `/docs`, `/todo`) so the family is discoverable as a chain.

## v1.0.8

Fixed the release workflow. v1.0.7's CI failed because an "Inspect plugin output" step still `cat`'d `dist/plugin/settings.json`, which was deleted in v1.0.7. Retargeted that step to `hooks/hooks.json` and removed stale `settings.json` references from the e2e trigger filters.

## v1.0.7

Deleted the plugin's `settings.json`. It had been reduced to `{}` after `statusLine` moved to user scope in v1.0.4, so it contributed nothing and existed only as a historical placeholder. Added a "Verifying install/uninstall changes" section to `CLAUDE.md` documenting the principle-based uninstall-reinstall test cycle. (Note: v1.0.7's GitHub Release was never published because of the CI failure fixed in v1.0.8; the tag is orphaned.)

## v1.0.6

Removed `voiceEnabled` from `user.settings.json`. VibeStack assumes a dedicated voice-input tool rather than Claude's built-in voice mode, so the setting was superfluous opinion-shaping.

## v1.0.5

Removed the redundant `enabledPlugins` block from `user.settings.json`. `claude plugin install` already chain-installs and auto-enables the LSP and frontend-design plugins via `plugin.json`'s `dependencies` field, so duplicating them in the settings template was dead weight. `plugin.json` `dependencies` is now the single source of truth for plugin enablement.

## v1.0.4

Moved the main `statusLine` to user scope. Claude only allows plugins to contribute `subagentStatusLine` at plugin scope, not the main `statusLine`, so the plugin's `settings.json` `statusLine` block was silently ignored. The fix ships `statusLine` in `user.settings.json` pointing at `~/.claude/hooks/statusline.sh`, which `install.sh` now fetches and drops at user level.

## v1.0.3

Fixed the Stop hook and statusLine registration. Plugin hooks must live in `hooks/hooks.json`, not the plugin's root `settings.json`; the hook block in `settings.json` was silently ignored, so the Stop notification sound never fired. Moved the hook registration to the canonical location, matching every official Anthropic plugin.

## v1.0.2

CI: trigger e2e on `VERSION` bumps so release commits are not reported as failed.

## v1.0.1

Restructured the plugin to the repo root and fixed a broken `marketplace.json` shape. The repo root is now the plugin root: `.claude-plugin/`, `skills/`, and `hooks/` all live at the top level, so `claude plugin marketplace add vibestackmd/vibestack` finds everything in place.

## v1.0.0

First stable release. VibeStack installs at the user level (`~/.claude/`) via `curl | bash` or `claude plugin install`. Ships a family of skills, a Stop-notification hook, a directory statusline, and opinionated user-level settings. The `curl | bash` installer auto-installs the Claude CLI if missing and chain-installs the four official LSP plugins plus `frontend-design` via the plugin manifest's `dependencies`.
