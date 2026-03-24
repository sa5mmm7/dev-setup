#!/usr/bin/env bash
# shellcheck disable=SC2154  # PYTHON_VERSIONS loaded from config/team.env via lib.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh disable=SC1091
source "${SCRIPT_DIR}/../lib.sh"

install_pyenv() {
  if ! check_command pyenv; then
    info "Installing pyenv via curl installer..."
    # Install pyenv build dependencies
    sudo apt-get install -y \
      build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
      libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev \
      libxmlsec1-dev libffi-dev liblzma-dev
    curl -fsSL https://pyenv.run | bash
    # shellcheck disable=SC2016
    append_zshrc 'export PYENV_ROOT="$HOME/.pyenv"'
    # shellcheck disable=SC2016
    append_zshrc '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"'
    # Make pyenv available in the current session
    export PYENV_ROOT="${HOME}/.pyenv"
    export PATH="${PYENV_ROOT}/bin:${PATH}"
  else
    info "pyenv already installed."
    info "Checking for pyenv updates..."
    pyenv update || warn "pyenv update failed — continuing."
  fi
}

install_ruff() {
  if ! check_command ruff; then
    info "Installing Ruff..."
    curl -LsSf https://astral.sh/ruff/install.sh | sh
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

  local profile
  profile="$(shell_profile)"
  # shellcheck disable=SC2016  # single quotes intentional: literal string in profile
  grep -qxF 'eval "$(pyenv init -)"' "${profile}" 2>/dev/null \
    && ok "pyenv init in ${profile}" \
    || fail "pyenv init missing from ${profile} — run: ./run-onboarding.sh 4"
}

main() {
  ensure_apt
  install_pyenv
  install_python_versions
  install_ruff
  # shellcheck disable=SC2016  # single quotes intentional: literal string in profile
  if append_zshrc 'eval "$(pyenv init -)"'; then
    note "$(shell_profile) was updated — run: source $(shell_profile)  (or open a new terminal)"
  fi
  install_step_extensions "${SCRIPT_DIR}"
  info "Step 4 (Python) complete. Use 'pyenv local <version>' in repo roots as needed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
