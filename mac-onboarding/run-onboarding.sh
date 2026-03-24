#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ONBOARDING_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=scripts/lib.sh disable=SC1091
source "${SCRIPT_DIR}/scripts/lib.sh"

usage() {
  cat <<EOF
Usage: $0 [step]

Runs the full macOS onboarding sequence, or a single step.

Steps:
  1  (gcp)    Install and configure GCP CLI
  2  (git)    Install git, set up SSH keys
  3  (podman) Install Podman
  4  (python) Install pyenv + Python versions
  5  (vscode) Install VS Code, extensions, and workspace config

Examples:
  $0           # run all steps
  $0 5         # run only step 5
  $0 vscode    # same as above
EOF
}

run_step() {
  local script="${SCRIPT_DIR}/scripts/${1}"
  shift
  echo ""
  echo "========================================"
  echo " Running: ${script##*/scripts/}"
  echo "========================================"
  bash "${script}" "$@"
}

install_project_tool() {
  mkdir -p "${HOME}/.local/bin"
  ln -sf "${ONBOARDING_ROOT}/project-devcontainer.sh" "${HOME}/.local/bin/project-devcontainer"
  # shellcheck disable=SC2016
  if append_zshrc 'export PATH="${HOME}/.local/bin:${PATH}"'; then
    echo "[WARN] ~/.zshrc was updated — run: source ~/.zshrc  (or open a new terminal)"
  fi
  echo "[INFO] Installed: project-devcontainer (run from any repo root to set up dev container)"
}

run_all() {
  run_step 01-gcp/run.sh
  run_step 02-git/run.sh
  run_step 03-podman/run.sh
  run_step 04-python/run.sh
  run_step 05-vscode/run.sh
  install_project_tool
  echo ""
  echo "[INFO] All steps complete. Running doctor..."
  bash "${SCRIPT_DIR}/onboarding-doctor.sh"
  if [[ "${ZSHRC_UPDATED:-false}" == "true" ]]; then
    echo ""
    echo "⚠️  ~/.zshrc was updated during this run — run: source ~/.zshrc  (or open a new terminal)"
  fi
}

case "${1:-all}" in
  all)       run_all ;;
  1|gcp)     run_step 01-gcp/run.sh ;;
  2|git)     run_step 02-git/run.sh ;;
  3|podman)  run_step 03-podman/run.sh ;;
  4|python)  run_step 04-python/run.sh ;;
  5|vscode)  run_step 05-vscode/run.sh "${@:2}" ;;
  -h|--help) usage ;;
  *)         echo "[ERROR] Unknown step: ${1}"; usage; exit 1 ;;
esac
