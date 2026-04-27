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

upload_ssh_signing_key() {
  local signing_key="$1" title="$2" output

  if output="$(gh ssh-key add "${signing_key}" --type signing --title "${title}" 2>&1)"; then
    info "SSH signing key uploaded to GitHub."
    return
  fi

  if [[ "${output}" == *"admin:ssh_signing_key"* ]]; then
    info "Refreshing GitHub auth scope for SSH signing keys..."
    if gh auth refresh -h github.com -s admin:ssh_signing_key; then
      if output="$(gh ssh-key add "${signing_key}" --type signing --title "${title}" 2>&1)"; then
        info "SSH signing key uploaded to GitHub."
        return
      fi
    else
      warn "Could not refresh GitHub auth scope for SSH signing keys."
    fi
  fi

  if [[ "${output}" == *"already exists"* || "${output}" == *"key is already in use"* ]]; then
    info "SSH signing key already present on GitHub."
  else
    warn "Could not upload SSH signing key to GitHub. If commits are not verified, run: gh ssh-key add ${signing_key} --type signing --title \"${title}\""
    warn "${output}"
  fi
}

configure_ssh_signing() {
  local signing_key="" title
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

  title="Signing key ($(hostname))"
  upload_ssh_signing_key "${signing_key}" "${title}"

  # Add key to ssh-agent so commits work in the current session
  local key_private="${signing_key%.pub}"
  if ssh-add "${key_private}" 2>/dev/null; then
    info "SSH key added to agent."
  else
    warn "Could not add SSH key to agent — if commits fail, run: ssh-add ${key_private}"
  fi
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
  if check_command git; then
    ok "git installed"
  else
    fail "git not found — run: ./run-onboarding.sh 2"
  fi

  if check_command gh; then
    ok "GitHub CLI installed"
  else
    fail "gh not found — run: ./run-onboarding.sh 2"
  fi

  if check_command gh; then
    if gh auth status >/dev/null 2>&1; then
      ok "GitHub authenticated"
    else
      fail "Not authenticated with GitHub — run: ./run-onboarding.sh 2"
    fi
  fi

  local name email
  name="$(git config --global user.name 2>/dev/null || true)"
  email="$(git config --global user.email 2>/dev/null || true)"
  if [[ -n "${name}" ]]; then
    ok "git user.name: ${name}"
  else
    fail "git user.name not set — run: ./run-onboarding.sh 2"
  fi
  if [[ -n "${email}" ]]; then
    ok "git user.email: ${email}"
  else
    fail "git user.email not set — run: ./run-onboarding.sh 2"
  fi

  local signing signing_format signing_key
  signing="$(git config --global commit.gpgsign 2>/dev/null || true)"
  if [[ "${signing}" == "true" ]]; then
    ok "commit signing enabled"
  else
    fail "commit signing not enabled — run: ./run-onboarding.sh 2"
  fi

  signing_format="$(git config --global gpg.format 2>/dev/null || true)"
  if [[ "${signing_format}" == "ssh" ]]; then
    ok "git signing format: ssh"
  else
    fail "git signing format is not ssh — run: ./run-onboarding.sh 2"
  fi

  signing_key="$(git config --global user.signingkey 2>/dev/null || true)"
  if [[ -n "${signing_key}" && -f "${signing_key}" ]]; then
    ok "git signing key exists: ${signing_key}"
  else
    fail "git signing key is missing or does not point to a file — run: ./run-onboarding.sh 2"
  fi

  if [[ -n "${signing_key}" && -f "${signing_key}" ]] && check_command gh && gh auth status >/dev/null 2>&1; then
    local local_key github_keys output
    local_key="$(awk '{print $1 " " $2}' "${signing_key}")"
    if output="$(gh api user/ssh_signing_keys --paginate --jq '.[].key' 2>&1)"; then
      github_keys="$(printf "%s\n" "${output}" | awk '{print $1 " " $2}')"
      if printf "%s\n" "${github_keys}" | grep -qxF "${local_key}"; then
        ok "SSH signing key present on GitHub"
      else
        fail "SSH signing key is not present on GitHub — run: ./run-onboarding.sh 2"
      fi
    elif [[ "${output}" == *"admin:ssh_signing_key"* ]]; then
      fail "GitHub CLI is missing admin:ssh_signing_key scope — run: gh auth refresh -h github.com -s admin:ssh_signing_key"
    else
      fail "Could not check GitHub SSH signing keys: ${output}"
    fi
  fi
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
