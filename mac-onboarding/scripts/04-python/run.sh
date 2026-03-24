#!/usr/bin/env bash
# shellcheck disable=SC2154  # PYTHON_VERSIONS loaded from config/team.env via lib.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh disable=SC1091
source "${SCRIPT_DIR}/../lib.sh"

install_pyenv() {
  if ! check_command pyenv; then
    info "Installing pyenv..."
    brew install pyenv
  else
    info "pyenv already installed."
    if brew outdated pyenv | grep -q pyenv; then
      info "Upgrading pyenv to ensure latest Python definitions..."
      brew upgrade pyenv
    else
      info "pyenv is up to date."
    fi
  fi
}

install_ruff() {
  if ! check_command ruff; then
    info "Installing Ruff..."
    brew install ruff
  else
    info "Ruff already installed."
  fi
}

install_python_versions() {
  for v in "${PYTHON_VERSIONS[@]}"; do
    if pyenv versions --bare | grep -qx "${v}"; then
      info "Python ${v} already installed in pyenv."
    else
      info "Installing Python ${v} via pyenv..."
      env PYTHON_CONFIGURE_OPTS="--enable-shared" pyenv install -s "${v}"
    fi
  done
}

check_python() {
  printf "\n🔍 Python (step 4)\n"
  if ! check_command pyenv; then
    fail "pyenv not found — run: ./run-onboarding.sh 4"
  else
    ok "pyenv installed"
    for v in "${PYTHON_VERSIONS[@]}"; do
      [[ -d "${HOME}/.pyenv/versions/${v}" ]] \
        && ok "Python ${v} installed" \
        || fail "Python ${v} not found — run: ./run-onboarding.sh 4"
    done
  fi

  check_command ruff \
    && ok "Ruff installed" \
    || fail "Ruff not found — run: ./run-onboarding.sh 4"

  # shellcheck disable=SC2016  # single quotes intentional: literal string in .zshrc
  grep -qxF 'eval "$(pyenv init -)"' ~/.zshrc 2>/dev/null \
    && ok "pyenv init in ~/.zshrc" \
    || fail "pyenv init missing from ~/.zshrc — run: ./run-onboarding.sh 4"
}

main() {
  ensure_homebrew
  install_pyenv
  install_python_versions
  install_ruff
  # shellcheck disable=SC2016  # single quotes intentional: literal string in .zshrc
  if append_zshrc 'eval "$(pyenv init -)"'; then
    note "${HOME}/.zshrc was updated — run: source ~/.zshrc  (or open a new terminal)"
  fi
  install_step_extensions "${SCRIPT_DIR}"
  info "Step 4 (Python) complete. Use 'pyenv local <version>' in repo roots as needed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
