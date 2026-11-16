#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Fails if any commit in a range is not authored and committed by Sklyvan,
# if its message carries attribution lines, or if it contains the em dash.
# It fails closed: a range that cannot be resolved is an error.
# Usage: scripts/check-authorship.sh [<base>..<head>]   (default: origin/main..HEAD)
set -euo pipefail

# Replace refs could swap a commit for another one locally: ignore them.
export GIT_NO_REPLACE_OBJECTS=1

here="$(cd "$(dirname "$0")" && pwd)"
range="${1:-origin/main..HEAD}"
allowed_name='Sklyvan'
allowed_emails='joangraciataribo@gmail.com 37016233+Sklyvan@users.noreply.github.com'
em_dash="$(printf '\xe2\x80\x94')"

if [[ "$range" != *..* ]]; then
  echo "error: '$range' is not a <base>..<head> range" >&2
  exit 2
fi
for end in "${range%%..*}" "${range##*..}"; do
  if ! git rev-parse --verify --quiet "${end}^{commit}" > /dev/null; then
    echo "error: cannot resolve '$end' in range '$range'" >&2
    exit 2
  fi
done

email_allowed() {
  local candidate
  for candidate in $allowed_emails; do
    [[ "$1" == "$candidate" ]] && return 0
  done
  return 1
}

# A plain assignment, so that a failing `git rev-list` aborts the script.
commits="$(git rev-list "$range")"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

failed=0
count=0
for sha in $commits; do
  count=$((count + 1))
  short="${sha:0:9}"
  for role in a c; do
    name="$(git show -s --format="%${role}n" "$sha")"
    email="$(git show -s --format="%${role}e" "$sha")"
    if [[ "$name" != "$allowed_name" ]] || ! email_allowed "$email"; then
      [[ "$role" == a ]] && label=author || label=committer
      echo "error: $short has $label '$name <$email>', expected $allowed_name" >&2
      failed=1
    fi
  done
  git show -s --format=%B "$sha" > "$tmp/message"
  if ! "$here/check-attribution.sh" "$tmp/message" 2> "$tmp/errors"; then
    echo "error: $short has a rejected commit message:" >&2
    cat "$tmp/errors" >&2
    failed=1
  fi
  if grep -q "$em_dash" "$tmp/message"; then
    echo "error: $short has an em dash (U+2014) in its commit message" >&2
    failed=1
  fi
done

if [[ "$count" -eq 0 && "${GITHUB_EVENT_NAME:-}" == "pull_request" ]]; then
  echo "error: no commits found in $range for a pull request" >&2
  exit 1
fi
if [[ "$failed" -ne 0 ]]; then
  echo "authorship check failed for $range" >&2
  exit 1
fi
echo "authorship check passed: $count commit(s) in $range"
