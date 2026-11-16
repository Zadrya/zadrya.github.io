# SPDX-License-Identifier: GPL-3.0-or-later
#
# Local parity: the lint, test, licenses, authorship and commitlint jobs in CI
# call these targets. CodeQL, Scorecard and dependency review only run in CI.

SHELL := bash
.DEFAULT_GOAL := help

BASE ?= origin/main
COMMITLINT := npx --yes --package @commitlint/cli@21.2.4 -- commitlint

.PHONY: help setup check ci lint licenses test authorship commitlint commitlint-message commitlint-title

help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-20s %s\n", $$1, $$2}'

setup: ## Install the git hooks in this clone
	lefthook install

check: lint licenses test ## Fast checks, run before every commit

ci: check authorship commitlint ## Everything CI runs, run before opening a pull request

lint: ## Lint workflows, YAML, Markdown and shell scripts
	actionlint
	zizmor --no-progress .github/workflows
	yamllint --strict .
	markdownlint-cli2 "**/*.md"
	shellcheck scripts/*.sh .lefthook/*/*.sh
	scripts/check-no-em-dash.sh

licenses: ## Check that every file has license information (REUSE)
	reuse lint

test: ## Run the tests
	scripts/test-hooks.sh

authorship: ## Check author, committer and attribution lines of BASE..HEAD
	scripts/check-authorship.sh $(BASE)..HEAD

commitlint: ## Check that the commits in BASE..HEAD are conventional
	$(COMMITLINT) --from $(BASE) --to HEAD --verbose

commitlint-message: ## Check one commit message file (FILE=path), used by the commit-msg hook
	$(COMMITLINT) --edit $(FILE)

commitlint-title: ## Check the pull request title in the PR_TITLE environment variable
	@[[ -n "$$PR_TITLE" ]] || { echo "error: PR_TITLE is empty" >&2; exit 1; }
	@printf '%s\n' "$$PR_TITLE" | $(COMMITLINT) --verbose
