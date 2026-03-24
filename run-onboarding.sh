#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname)" == "Darwin" ]]; then
  exec bash "${SCRIPT_DIR}/mac-onboarding/run-onboarding.sh" "$@"
elif grep -qi microsoft /proc/version 2>/dev/null; then
  exec bash "${SCRIPT_DIR}/windows-onboarding/run-onboarding.sh" "$@"
else
  echo "[ERROR] Unsupported OS. Run from mac-onboarding/ or windows-onboarding/ directly."
  exit 1
fi
