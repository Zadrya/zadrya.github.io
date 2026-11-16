#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Rejects a commit message that carries AI attribution lines.
# Usage: scripts/check-attribution.sh <commit-message-file>
set -euo pipefail

pattern='co-authored-by:|claude-session:|generated with \[?claude code'

if grep -Eiq "$pattern" "$1"; then
  echo "error: the commit message contains a forbidden attribution line:" >&2
  grep -Ein "$pattern" "$1" >&2
  echo "Sklyvan is the only author. Remove the line and commit again." >&2
  exit 1
fi
