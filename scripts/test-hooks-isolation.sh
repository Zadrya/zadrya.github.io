#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Regression test: scripts/test-hooks.sh must never touch a repository other
# than its own throwaway one, even when git's hook environment points
# somewhere else. Git exports GIT_INDEX_FILE to every pre-commit hook, and in
# a linked worktree or a submodule it also exports GIT_DIR. The sentinel below
# has that shape: a main repository and a linked worktree with a staged change.
set -euo pipefail

scripts="$(cd "$(dirname "$0")" && pwd)"
local_git_vars="$(git rev-parse --local-env-vars)"
# shellcheck disable=SC2086
unset $local_git_vars

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
sentinel="$tmp/sentinel"
linked="$tmp/linked"

git init -q -b main "$sentinel"
git -C "$sentinel" config user.name sentinel
git -C "$sentinel" config user.email sentinel@example.com
echo tracked > "$sentinel/tracked.txt"
git -C "$sentinel" add tracked.txt
git -C "$sentinel" commit -q -m "chore: sentinel"
git -C "$sentinel" worktree add -q -b linked "$linked"
echo staged > "$linked/staged.txt"
git -C "$linked" add staged.txt
echo dirty >> "$linked/tracked.txt"

linked_git_dir="$(git -C "$linked" rev-parse --absolute-git-dir)"

state() {
  git -C "$sentinel" for-each-ref
  git -C "$sentinel" config --list --local
  git -C "$sentinel" status --porcelain
  git -C "$linked" status --porcelain
  git -C "$sentinel" count-objects -v | grep -E '^(count|in-pack):'
  git -C "$sentinel" reflog show --all | wc -l
  cksum < "$sentinel/.git/index"
  cksum < "$linked_git_dir/index"
}

check() { # <description> <variable assignments...>
  local description="$1" before after
  shift
  before="$(state)"
  env "$@" "$scripts/test-hooks.sh" > /dev/null
  after="$(state)"
  if [[ "$before" != "$after" ]]; then
    echo "FAIL: scripts/test-hooks.sh changed a repository it does not own ($description)"
    exit 1
  fi
  echo "ok: isolated with $description"
}

check 'the environment of a linked worktree hook' \
  GIT_DIR="$linked_git_dir" GIT_INDEX_FILE="$linked_git_dir/index"
check 'GIT_DIR of the main repository' GIT_DIR="$sentinel/.git"
check 'GIT_OBJECT_DIRECTORY alone' GIT_OBJECT_DIRECTORY="$sentinel/.git/objects"
check 'GIT_COMMON_DIR alone' GIT_COMMON_DIR="$sentinel/.git"
check 'GIT_WORK_TREE alone' GIT_WORK_TREE="$linked"
