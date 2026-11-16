#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Regression test: scripts/test-hooks.sh must never touch a repository other
# than its own throwaway one, even when git's hook environment (GIT_DIR,
# GIT_INDEX_FILE) points somewhere else, as it does inside a pre-commit hook
# of a linked worktree.
set -euo pipefail

scripts="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC2046
unset $(git rev-parse --local-env-vars)

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
sentinel="$tmp/sentinel"

git init -q -b main "$sentinel"
git -C "$sentinel" -c user.name=sentinel -c user.email=sentinel@example.com \
  commit -q --allow-empty -m "chore: sentinel"

state() {
  git -C "$sentinel" rev-parse HEAD
  git -C "$sentinel" for-each-ref
  git -C "$sentinel" config --get core.bare
}

before="$(state)"
GIT_DIR="$sentinel/.git" GIT_INDEX_FILE="$sentinel/.git/index" "$scripts/test-hooks.sh" > /dev/null
after="$(state)"

if [[ "$before" != "$after" ]]; then
  echo "FAIL: scripts/test-hooks.sh changed a repository it does not own"
  exit 1
fi
echo "ok: the hook tests are isolated from the surrounding repository"
