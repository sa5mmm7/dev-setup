#!/usr/bin/env bash
# shellcheck disable=SC2154  # ARTIFACT_REGISTRY and other team vars loaded from team.env via lib.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh disable=SC1091
source "${SCRIPT_DIR}/../lib.sh"

install_podman() {
  if ! check_command podman; then
    info "Installing Podman..."
    sudo apt-get install -y podman
  else
    info "Podman already installed."
  fi
}

# On WSL2, Podman runs natively as Linux containers — no podman machine needed.
verify_podman_native() {
  info "Verifying Podman can run natively in WSL2..."
  if podman info >/dev/null 2>&1; then
    info "Podman is working correctly."
  else
    warn "Podman info check failed — Podman may not be fully configured. Try restarting WSL2."
  fi
}

configure_podman_registries() {
  info "Configuring Podman registry search order..."
  local conf_dir="/etc/containers/registries.conf.d"
  local conf="unqualified-search-registries = [\"${ARTIFACT_REGISTRY}\", \"ghcr.io\", \"docker.io\"]"
  sudo mkdir -p "${conf_dir}"
  if printf '%s\n' "${conf}" | sudo tee "${conf_dir}/10-team.conf" > /dev/null; then
    info "Registry search configured: ${ARTIFACT_REGISTRY}, ghcr.io, docker.io"
  else
    warn "Could not configure registry search — you may need to specify full registry paths."
  fi
}

login_ghcr() {
  if ! check_command gh; then
    warn "gh CLI not found — skipping GHCR login. Run step 2 first."
    return
  fi
  if podman login --get-login ghcr.io >/dev/null 2>&1; then
    info "Already logged into ghcr.io."
    return
  fi
  local username
  username="$(gh api user --jq '.login')"
  info "Logging into GitHub Container Registry as ${username}..."
  gh auth token | podman login ghcr.io -u "${username}" --password-stdin
}

check_podman() {
  printf "\n🔍 Podman (step 3)\n"
  if ! check_command podman; then
    fail "Podman not found — run: ./run-onboarding.sh 3"
    return
  fi
  ok "Podman installed"

  podman info >/dev/null 2>&1 \
    && ok "Podman running (native WSL2 containers)" \
    || fail "Podman not functional — run: ./run-onboarding.sh 3"

  podman login --get-login ghcr.io >/dev/null 2>&1 \
    && ok "Logged into ghcr.io" \
    || fail "Not logged into ghcr.io — run: ./run-onboarding.sh 3"
}

main() {
  ensure_apt
  install_podman
  verify_podman_native
  configure_podman_registries
  login_ghcr
  configure_vscode_for_podman
  install_step_extensions "${SCRIPT_DIR}"
  info "Step 3 (Podman) complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
