#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Rejects a commit message that carries AI attribution or co-author lines.
# This is the single place where the forbidden patterns are defined.
# Usage: scripts/check-attribution.sh <commit-message-file>
set -euo pipefail

if [[ $# -ne 1 || ! -r "$1" ]]; then
  echo "usage: $0 <commit-message-file>" >&2
  exit 2
fi

pattern='co-authored-by[[:space:]]*:'
pattern+='|assisted-by[[:space:]]*:'
pattern+='|claude-session[[:space:]]*:'
pattern+='|generated[[:space:]]+(with|by)[[:space:]]+\[?claude'

# With `git commit -v` the message file also holds the diff below a scissors
# line. Git discards that part, so it is not checked.
message="$(sed '/^# -\{24\} >8 -\{24\}$/,$d' "$1")"

# The message is matched from a variable, never from a pipe, so a long message
# cannot hide a match behind a broken pipe.
if matches="$(grep -Ein "$pattern" <<< "$message")"; then
  echo "error: the commit message contains a forbidden attribution line:" >&2
  echo "$matches" >&2
  echo "Sklyvan is the only author. Remove the line and commit again." >&2
  exit 1
fi
