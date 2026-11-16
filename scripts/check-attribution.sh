#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Rejects a commit message that carries AI attribution or co-author lines.
# This is the single place where the forbidden patterns are defined.
# Usage: scripts/check-attribution.sh [--hook] <commit-message-file>
#
# --hook is for the commit-msg hook only: with `git commit -v` the message file
# also holds the diff below a scissors line, which git discards, so that part
# is skipped. Without --hook the whole text is checked, which is what stored
# commit messages need: there, text after a scissors line is part of the message.
set -euo pipefail

hook=0
if [[ "${1:-}" == "--hook" ]]; then
  hook=1
  shift
fi
if [[ $# -ne 1 || ! -r "$1" ]]; then
  echo "usage: $0 [--hook] <commit-message-file>" >&2
  exit 2
fi

pattern='co-authored-by[[:space:]]*:'
pattern+='|assisted-by[[:space:]]*:'
pattern+='|claude-session[[:space:]]*:'
pattern+='|(generated|created|written|authored)[[:space:]]+(with|by|using)[[:space:]]+[^[:alnum:]]*claude'
pattern+='|noreply@anthropic\.com'
pattern+='|claude\.ai/code'

if [[ "$hook" -eq 1 ]]; then
  message="$(sed '/^# -\{24\} >8 -\{24\}$/,$d' "$1")"
else
  message="$(cat "$1")"
fi

# The message is matched from a variable, never from a pipe, so a long message
# cannot hide a match behind a broken pipe.
if matches="$(grep -Ein "$pattern" <<< "$message")"; then
  echo "error: the commit message contains a forbidden attribution line:" >&2
  echo "$matches" >&2
  echo "Sklyvan is the only author. Remove the line and commit again." >&2
  exit 1
fi
