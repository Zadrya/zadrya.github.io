#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Fails if text contains the em dash (U+2014). Project style uses commas,
# colons or parentheses instead.
# Usage: scripts/check-no-em-dash.sh          checks every tracked text file
#        scripts/check-no-em-dash.sh <file>   checks one file (a commit message)
set -uo pipefail

em_dash="$(printf '\xe2\x80\x94')"

if [[ $# -ge 1 ]]; then
  grep -n "$em_dash" "$1"
else
  git grep -nI "$em_dash" -- . ':!LICENSE' ':!LICENSES' ':!CODE_OF_CONDUCT.md'
fi
status=$?

case "$status" in
  0)
    echo "error: em dash (U+2014) found, use a comma, a colon or parentheses" >&2
    exit 1
    ;;
  1) exit 0 ;;
  *)
    echo "error: the em dash search itself failed (exit $status)" >&2
    exit 2
    ;;
esac
