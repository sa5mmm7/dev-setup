#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh disable=SC1091
source "${SCRIPT_DIR}/../lib.sh"

STATE_FILE="${HOME}/.onboarding-state"

# --- install ---

install_git() {
  if ! check_command git; then
    info "Installing git..."
    brew install git
  else
    info "git already installed."
  fi
}

install_gh_cli() {
  if ! check_command gh; then
    info "Installing GitHub CLI..."
    brew install gh
  else
    info "GitHub CLI already installed."
  fi
}

# --- configure ---

configure_git_identity() {
  local name email
  name="$(git config --global user.name 2>/dev/null || true)"
  email="$(git config --global user.email 2>/dev/null || true)"

  if [[ -z "${name}" ]]; then
    printf "\nEnter your full name for git commits: "
    read -r name
    git config --global user.name "${name}"
    info "Set git user.name: ${name}"
  else
    info "git user.name already set: ${name}"
  fi

  if [[ -z "${email}" ]]; then
    printf "Enter your email for git commits: "
    read -r email
    git config --global user.email "${email}"
    info "Set git user.email: ${email}"
  else
    info "git user.email already set: ${email}"
  fi
}

gh_auth_login() {
  if gh auth status >/dev/null 2>&1; then
    info "Already authenticated with GitHub."
    return
  fi
  info "Starting GitHub authentication..."
  info "Your browser will open — approve access, then return here."
  gh auth login --hostname github.com --git-protocol ssh
}

configure_ssh_signing() {
  local signing_key=""
  for key in "${HOME}/.ssh/id_ed25519" "${HOME}/.ssh/id_ecdsa" "${HOME}/.ssh/id_rsa"; do
    if [[ -f "${key}.pub" ]]; then
      signing_key="${key}.pub"
      break
    fi
  done

  if [[ -z "${signing_key}" ]]; then
    warn "No SSH public key found — skipping commit signing config. Re-run step 2 after key setup."
    COMMIT_SIGNING="false"
    return
  fi

  git config --global gpg.format ssh
  git config --global user.signingkey "${signing_key}"
  git config --global commit.gpgsign true
  info "SSH commit signing configured with ${signing_key}"

  # Add key to ssh-agent so commits work in the current session
  local key_private="${signing_key%.pub}"
  ssh-add "${key_private}" 2>/dev/null \
    && info "SSH key added to agent." \
    || warn "Could not add SSH key to agent — if commits fail, run: ssh-add ${key_private}"
}

write_state() {
  touch "${STATE_FILE}"
  if grep -q "^COMMIT_SIGNING=" "${STATE_FILE}" 2>/dev/null; then
    sed -i '' "s|^COMMIT_SIGNING=.*|COMMIT_SIGNING=${COMMIT_SIGNING}|" "${STATE_FILE}"
  else
    echo "COMMIT_SIGNING=${COMMIT_SIGNING}" >> "${STATE_FILE}"
  fi
  info "Saved state to ${STATE_FILE}"
}

# --- checks ---

check_git() {
  printf "\n🔍 Git + GitHub (step 2)\n"
  check_command git \
    && ok "git installed" \
    || fail "git not found — run: ./run-onboarding.sh 2"

  check_command gh \
    && ok "GitHub CLI installed" \
    || fail "gh not found — run: ./run-onboarding.sh 2"

  if check_command gh; then
    gh auth status >/dev/null 2>&1 \
      && ok "GitHub authenticated" \
      || fail "Not authenticated with GitHub — run: ./run-onboarding.sh 2"
  fi

  local name email
  name="$(git config --global user.name 2>/dev/null || true)"
  email="$(git config --global user.email 2>/dev/null || true)"
  [[ -n "${name}" ]]  && ok "git user.name: ${name}"  || fail "git user.name not set — run: ./run-onboarding.sh 2"
  [[ -n "${email}" ]] && ok "git user.email: ${email}" || fail "git user.email not set — run: ./run-onboarding.sh 2"

  local signing
  signing="$(git config --global commit.gpgsign 2>/dev/null || true)"
  [[ "${signing}" == "true" ]] \
    && ok "commit signing enabled" \
    || note "commit signing not enabled (run step 2 to configure)"
}

# --- main ---

main() {
  ensure_homebrew
  install_git
  install_gh_cli
  configure_git_identity
  gh_auth_login
  COMMIT_SIGNING="true"
  configure_ssh_signing
  write_state
  install_step_extensions "${SCRIPT_DIR}"
  info "Step 2 (git) complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
