#!/usr/bin/env bash
# shellcheck disable=SC2154  # ARTIFACT_REGISTRY and other team vars loaded from team.env via lib.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib.sh"

install_podman() {
  if ! check_command podman; then
    info "Installing Podman..."
    brew install podman
  else
    info "Podman already installed."
  fi
}

init_podman_machine() {
  local cpus="${PODMAN_CPUS:-4}"
  local memory="${PODMAN_MEMORY_MB:-8192}"

  if ! podman machine list 2>/dev/null | grep -q "podman-machine-default"; then
    info "Initializing Podman machine (${cpus} CPUs, ${memory}MB RAM)..."
    podman machine init --cpus "${cpus}" --memory "${memory}"
    podman machine start
    return
  fi

  # Machine exists — update resources if needed then ensure it's running
  info "Configuring Podman machine resources (${cpus} CPUs, ${memory}MB RAM)..."
  if podman machine list 2>/dev/null | grep -q "Currently running"; then
    podman machine stop
  fi
  podman machine set --cpus "${cpus}" --memory "${memory}" || warn "Could not update Podman machine resources."
  podman machine start
}

configure_podman_registries() {
  info "Configuring Podman registry search order..."
  local conf
  conf="unqualified-search-registries = [\"${ARTIFACT_REGISTRY}\", \"ghcr.io\", \"docker.io\"]"
  podman machine ssh "sudo mkdir -p /etc/containers/registries.conf.d && printf '%s\n' '${conf}' | sudo tee /etc/containers/registries.conf.d/10-team.conf > /dev/null" \
    && info "Registry search configured: ${ARTIFACT_REGISTRY}, ghcr.io, docker.io" \
    || warn "Could not configure registry search — you may need to specify full registry paths."
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

  podman machine list 2>/dev/null | grep -q "Currently running" \
    && ok "Podman machine running" \
    || fail "Podman machine not running — run: ./run-onboarding.sh 3"

  podman login --get-login ghcr.io >/dev/null 2>&1 \
    && ok "Logged into ghcr.io" \
    || fail "Not logged into ghcr.io — run: ./run-onboarding.sh 3"
}

main() {
  ensure_homebrew
  install_podman
  init_podman_machine
  configure_podman_registries
  login_ghcr
  configure_vscode_for_podman
  install_step_extensions "${SCRIPT_DIR}"
  info "Step 3 (Podman) complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
