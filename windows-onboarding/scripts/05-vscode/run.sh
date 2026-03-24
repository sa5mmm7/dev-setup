#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../lib.sh disable=SC1091
source "${SCRIPT_DIR}/../lib.sh"

# --- install ---

install_vscode() {
  if check_command code; then
    info "VS Code already installed (accessible via Remote-WSL)."
    return
  fi

  # VS Code runs on Windows; 'code' is available in WSL2 via the Remote-WSL integration.
  # If it's not in PATH, the Windows-side VS Code installation is missing or not configured.
  error "VS Code 'code' command not found in WSL2 PATH.
Please install VS Code on Windows: https://code.visualstudio.com/download
Then install the Remote Development extension pack and reopen this terminal.
The 'code' command becomes available in WSL2 automatically once VS Code is installed on Windows."
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
  install_vscode
  install_extensions "${1:-}"
  # Apply Podman user settings now that VS Code is confirmed installed
  configure_vscode_for_podman
  info "Step 5 (VS Code) complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
