#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib.sh disable=SC1091
source "${SCRIPT_DIR}/../lib.sh"

# --- dependency checks ---

check_deps() {
  require_command brew "Homebrew is required. Run step 1 first, or install from https://brew.sh"
}

# --- install ---

install_vscode() {
  if check_command code; then
    info "VS Code already installed."
    return
  fi

  # VS Code may be installed as an app but 'code' not yet in PATH
  if [[ -d "/Applications/Visual Studio Code.app" ]]; then
    error "VS Code is installed but 'code' is not in PATH.
Open VS Code → Cmd+Shift+P → 'Shell Command: Install code command in PATH', then re-run this step."
  fi

  info "Installing Visual Studio Code via Homebrew cask..."
  brew install --cask visual-studio-code
  error "VS Code installed. Open it once, then run:
  Cmd+Shift+P → 'Shell Command: Install code command in PATH'
Then re-run: ./run-onboarding.sh 5"
}

install_extensions() {
  local force="${1:-}"
  local scripts_dir
  scripts_dir="$(dirname "${SCRIPT_DIR}")"
  for ext_file in "${scripts_dir}"/*/vscode-extensions.txt; do
    [[ -f "${ext_file}" ]] || continue
    install_step_extensions "$(dirname "${ext_file}")" "${force}"
  done
}

# --- checks ---

check_vscode() {
  printf "\n🔍 VS Code (step 5)\n"
  if ! check_command code; then
    fail "VS Code not found — run: ./run-onboarding.sh 5"
    return
  fi
  ok "VS Code installed"

  local installed_exts
  installed_exts="$(code --list-extensions 2>/dev/null || true)"
  local scripts_dir
  scripts_dir="$(dirname "${SCRIPT_DIR}")"
  while IFS= read -r ext || [[ -n "${ext}" ]]; do
    [[ -z "${ext}" || "${ext}" =~ ^# ]] && continue
    if echo "${installed_exts}" | grep -qi "^${ext}$"; then
      ok "Extension: ${ext}"
    else
      fail "Extension missing: ${ext} — run: ./run-onboarding.sh 5"
    fi
  done < <(cat "${scripts_dir}"/*/vscode-extensions.txt 2>/dev/null)
}

# --- main ---

main() {
  check_deps
  install_vscode
  install_extensions "${1:-}"
  # Apply Podman user settings now that VS Code is confirmed installed
  configure_vscode_for_podman
  info "Step 5 (VS Code) complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
