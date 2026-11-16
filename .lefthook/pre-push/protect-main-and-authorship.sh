#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Entry point of the pre-push hook. It is a lefthook script and not a command,
# because lefthook skips pre-push commands when the pushed commits change no
# files (an empty commit), and this check must always run.
set -euo pipefail

exec "$(git rev-parse --show-toplevel)/scripts/pre-push.sh"
