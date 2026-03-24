#!/usr/bin/env bash
# Bootstrap a new dev machine before the onboarding repo is cloned.
#
# Usage (once the repo is public):
#   curl -fsSL https://raw.githubusercontent.com/sa5mmm7/dev-setup/main/bootstrap.sh | bash
#
# What this does:
#   1. Installs git if missing (Xcode CLT on macOS, apt on WSL2)
#   2. Clones the onboarding repo to ~/dev-setup
#   3. Runs run-onboarding.sh
set -euo pipefail

REPO_URL="https://github.com/sa5mmm7/dev-setup.git"
CLONE_DIR="${HOME}/dev-setup"

# --- helpers ---
info() { echo "[INFO] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

# --- detect OS ---
if [[ "$(uname)" == "Darwin" ]]; then
  OS="mac"
elif grep -qi microsoft /proc/version 2>/dev/null; then
  OS="wsl2"
else
  error "Unsupported OS. Run mac-onboarding/ or windows-onboarding/ manually."
fi

# --- install git if missing ---
if ! command -v git >/dev/null 2>&1; then
  if [[ "${OS}" == "mac" ]]; then
    echo ""
    echo "Git is not installed. macOS will now prompt you to install the"
    echo "Xcode Command Line Tools (this includes git)."
    echo ""
    echo "After the install completes, run this script again:"
    echo "  curl -fsSL https://raw.githubusercontent.com/sa5mmm7/dev-setup/main/bootstrap.sh | bash"
    echo ""
    # Trigger the macOS install dialog
    git --version 2>/dev/null || true
    exit 0
  else
    info "Installing git via apt..."
    sudo apt-get update -qq
    sudo apt-get install -y git
  fi
fi

# --- clone or update repo ---
if [[ -d "${CLONE_DIR}/.git" ]]; then
  info "Repo already exists at ${CLONE_DIR} — pulling latest..."
  git -C "${CLONE_DIR}" pull --ff-only
else
  info "Cloning onboarding repo to ${CLONE_DIR}..."
  git clone "${REPO_URL}" "${CLONE_DIR}"
fi

# --- run onboarding ---
echo ""
info "Repo ready. Starting onboarding..."
exec bash "${CLONE_DIR}/run-onboarding.sh"
