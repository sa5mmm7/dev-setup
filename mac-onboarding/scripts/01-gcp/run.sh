#!/usr/bin/env bash
# shellcheck disable=SC2154  # GCP vars (GCP_PROJECT, ARTIFACT_REGISTRY, etc.) loaded from config/team.env via lib.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib.sh disable=SC1091
source "${SCRIPT_DIR}/../lib.sh"

# --- install ---

install_gcloud() {
  if check_command gcloud; then
    info "gcloud CLI already installed."
    return
  fi
  info "Installing Google Cloud SDK via Homebrew cask..."
  brew install --cask google-cloud-sdk
  # shellcheck disable=SC2016
  append_zshrc 'source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"'
  # shellcheck disable=SC2016
  append_zshrc 'source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"'
}

# --- configure ---

configure_gcloud() {
  local account
  account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true)"
  if [[ -n "${account}" ]]; then
    info "Already authenticated as ${account}."
  else
    info "Starting GCP authentication — your browser will open..."
    gcloud auth login
  fi

  local project
  project="$(gcloud config get-value project 2>/dev/null || true)"
  if [[ "${project}" == "${GCP_PROJECT}" ]]; then
    info "GCP project already set to ${GCP_PROJECT}."
  else
    info "Setting default project to ${GCP_PROJECT}..."
    gcloud config set project "${GCP_PROJECT}"
  fi

  local region
  region="$(gcloud config get-value compute/region 2>/dev/null || true)"
  if [[ "${region}" == "${GCP_REGION}" ]]; then
    info "GCP region already set to ${GCP_REGION}."
  else
    gcloud config set compute/region "${GCP_REGION}"
    gcloud config set compute/zone "${GCP_ZONE}"
    info "Set region: ${GCP_REGION}, zone: ${GCP_ZONE}"
  fi
}

configure_adc() {
  local adc_file="${HOME}/.config/gcloud/application_default_credentials.json"
  if [[ -f "${adc_file}" ]]; then
    info "Application Default Credentials already configured."
    return
  fi
  info "Configuring Application Default Credentials..."
  info "Your browser will open — log in with your ${TEAM_NAME} Google account."
  gcloud auth application-default login
}

configure_artifact_registry() {
  info "Configuring Docker credential helper for ${ARTIFACT_REGISTRY}/${ARTIFACT_REGISTRY_PROJECT}..."
  gcloud auth configure-docker "${ARTIFACT_REGISTRY}" --quiet
}

# --- checks ---

check_gcp() {
  printf "\n🔍 GCP (step 1)\n"
  if ! check_command gcloud; then
    fail "gcloud not found — run: ./run-onboarding.sh 1"
    return
  fi
  ok "gcloud CLI installed"

  local account
  account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true)"
  [[ -n "${account}" ]] \
    && ok "gcloud authenticated: ${account}" \
    || fail "gcloud not authenticated — run: ./run-onboarding.sh 1"

  local project
  project="$(gcloud config get-value project 2>/dev/null || true)"
  [[ "${project}" == "${GCP_PROJECT}" ]] \
    && ok "gcloud project: ${project}" \
    || fail "gcloud project not set to ${GCP_PROJECT} — run: ./run-onboarding.sh 1"

  local adc_file="${HOME}/.config/gcloud/application_default_credentials.json"
  [[ -f "${adc_file}" ]] \
    && ok "Application Default Credentials configured" \
    || fail "ADC not configured — run: ./run-onboarding.sh 1"

  podman login --get-login "${ARTIFACT_REGISTRY}" >/dev/null 2>&1 \
    && ok "Logged into ${ARTIFACT_REGISTRY}" \
    || fail "Not logged into ${ARTIFACT_REGISTRY} — run: ./run-onboarding.sh 1"
}

# --- main ---

main() {
  ensure_homebrew
  install_gcloud
  configure_gcloud
  configure_adc
  configure_artifact_registry
  install_step_extensions "${SCRIPT_DIR}"
  info "Step 1 (GCP) complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
