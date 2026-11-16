#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# pre-push hook. Git passes one line per pushed ref on standard input:
#   <local ref> <local sha> <remote ref> <remote sha>
# main only changes through pull requests, and every pushed commit must pass
# the authorship check. CI and the ruleset on main are the real enforcement;
# this hook only catches mistakes earlier.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
zero='0000000000000000000000000000000000000000'

git fetch --quiet origin main

while read -r _local_ref local_sha remote_ref _remote_sha; do
  if [[ "$remote_ref" == "refs/heads/main" ]]; then
    echo "error: do not push to main, open a pull request from a feature/ or fix/ branch" >&2
    exit 1
  fi
  [[ "$local_sha" == "$zero" ]] && continue # a branch deletion
  "$here/check-authorship.sh" "origin/main..$local_sha"
done
