#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Installs the pinned tools that `make ci` needs on a GitHub-hosted Ubuntu runner.
# Locally, install the same tools with Homebrew (see CLAUDE.md).
set -euo pipefail

pipx install yamllint==1.38.0
pipx install zizmor==1.32.0
pipx install reuse==6.3.0
npm install --global --no-fund --no-audit markdownlint-cli2@0.24.1
go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.12

if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "$(go env GOPATH)/bin" >> "$GITHUB_PATH"
fi
