#!/usr/bin/env bash
# shellcheck disable=SC2154  # PYTHON_VERSIONS (and other team vars) loaded from config/team.env via lib.sh
# Deploy VS Code workspace config and dev container setup into the current repo.
# Run from the root of the repo you want to configure, then commit the results.
#
# Usage:
#   cd /path/to/your-repo
#   /path/to/onboarding-setup/project-devcontainer.sh
set -euo pipefail

REAL_SCRIPT="$(readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${REAL_SCRIPT}")" && pwd)"
CONFIG_VSCODE="${SCRIPT_DIR}/config/vscode"
CONFIG_GIT="${SCRIPT_DIR}/config/git"

# Source lib.sh from the appropriate platform folder (or skip if already sourced by doctor).
# shellcheck disable=SC1091
if ! declare -f info >/dev/null 2>&1; then
  if [[ "$(uname)" == "Darwin" ]]; then
    source "${SCRIPT_DIR}/mac-onboarding/scripts/lib.sh"
  else
    source "${SCRIPT_DIR}/windows-onboarding/scripts/lib.sh"
  fi
fi

# --- prompts ---

select_python_path() {
  printf "\nSelect default Python interpreter for workspaces:\n\n"
  local options=()
  local v
  for v in "${PYTHON_VERSIONS[@]}"; do
    options+=("pyenv ${v}")
  done
  options+=("system python3")

  select _opt in "${options[@]}"; do
    if [[ "${REPLY}" -ge 1 && "${REPLY}" -le "${#PYTHON_VERSIONS[@]}" ]]; then
      PYTHON_PATH="${HOME}/.pyenv/versions/${PYTHON_VERSIONS[$((REPLY - 1))]}/bin/python"
      break
    elif [[ "${REPLY}" -eq $(( ${#PYTHON_VERSIONS[@]} + 1 )) ]]; then
      PYTHON_PATH="python3"
      break
    else
      echo "Invalid choice — enter 1-$(( ${#PYTHON_VERSIONS[@]} + 1 ))"
    fi
  done

  if [[ "${PYTHON_PATH}" != "python3" && ! -x "${PYTHON_PATH}" ]]; then
    warn "Interpreter not found at ${PYTHON_PATH} — run step 4 first to install it."
    warn "Defaulting to system python3. Re-run after step 4 to update."
    PYTHON_PATH="python3"
  fi

  info "Using interpreter: ${PYTHON_PATH}"
}

load_state() {
  COMMIT_SIGNING="false"
  local state_file="${HOME}/.onboarding-state"
  if [[ -f "${state_file}" ]]; then
    # shellcheck source=/dev/null
    source "${state_file}"
    info "Loaded onboarding state (commit signing: ${COMMIT_SIGNING})"
  else
    warn "No onboarding state found — run step 2 first to configure commit signing. Defaulting to off."
  fi
}

select_container_python_version() {
  printf "\nNo Dockerfile found — select Python version for dev container:\n\n"
  local options=()
  local v
  for v in "${PYTHON_VERSIONS[@]}"; do
    options+=("${v%.*}")  # major.minor only (e.g. 3.9.18 → 3.9)
  done

  select _opt in "${options[@]}"; do
    if [[ "${REPLY}" -ge 1 && "${REPLY}" -le "${#options[@]}" ]]; then
      CONTAINER_PYTHON_VERSION="${options[$((REPLY - 1))]}"
      break
    else
      echo "Invalid choice — enter 1-${#options[@]}"
    fi
  done
  info "Dev container will use Python ${CONTAINER_PYTHON_VERSION}"
}

# --- deploy ---

deploy_vscode_settings() {
  if [[ ! -f "${CONFIG_VSCODE}/settings.json" ]]; then
    error "Config file not found: ${CONFIG_VSCODE}/settings.json — repo may be incomplete."
  fi
  mkdir -p .vscode
  backup_if_exists ".vscode/settings.json"
  sed -e "s|__PYTHON_PATH__|${PYTHON_PATH}|g" \
      -e "s|__COMMIT_SIGNING__|${COMMIT_SIGNING}|g" \
      "${CONFIG_VSCODE}/settings.json" > .vscode/settings.json
  info "Deployed .vscode/settings.json"
}

deploy_workspace_file() {
  backup_if_exists "onboarding.code-workspace"
  sed "s|__PYTHON_PATH__|${PYTHON_PATH}|g" "${CONFIG_VSCODE}/workspace.json" > onboarding.code-workspace
  info "Deployed onboarding.code-workspace"
}

deploy_devcontainer() {
  mkdir -p .devcontainer

  local dockerfile_path
  if [[ -f "Dockerfile.dev" ]]; then
    dockerfile_path="../Dockerfile.dev"
    info "Found Dockerfile.dev — dev container will use it."
  elif [[ -f "Dockerfile" ]]; then
    dockerfile_path="../Dockerfile"
    info "Found Dockerfile — dev container will use it."
  else
    select_container_python_version
    sed "s|__PYTHON_VERSION__|${CONTAINER_PYTHON_VERSION}|g" \
      "${CONFIG_VSCODE}/devcontainer.Dockerfile" > .devcontainer/Dockerfile
    dockerfile_path="Dockerfile"
    info "Generated Python ${CONTAINER_PYTHON_VERSION} dev container."
  fi

  backup_if_exists ".devcontainer/devcontainer.json"
  sed "s|__DOCKERFILE_PATH__|${dockerfile_path}|g" \
    "${CONFIG_VSCODE}/devcontainer.json" > .devcontainer/devcontainer.json
  info "Deployed .devcontainer/"
}

deploy_commit_editor_config() {
  mkdir -p .vscode
  safe_deploy "${CONFIG_VSCODE}/commit-message-editor.json" .vscode/commit-message-editor.json
  info "Deployed .vscode/commit-message-editor.json"
}

deploy_tasks() {
  mkdir -p .vscode
  safe_deploy "${CONFIG_VSCODE}/tasks.json" .vscode/tasks.json
  safe_deploy "${CONFIG_VSCODE}/install-requirements.sh" .vscode/install-requirements.sh
  chmod +x .vscode/install-requirements.sh
  info "Deployed .vscode/tasks.json and helpers"
}

deploy_git_configs() {
  safe_deploy "${CONFIG_GIT}/pre-commit-config.yaml" .pre-commit-config.yaml
  safe_deploy "${CONFIG_GIT}/gitmessage.txt" .gitmessage.txt
  info "Deployed .pre-commit-config.yaml and .gitmessage.txt"
}

# --- checks ---

check_project_files() {
  printf "\n🔍 Project config files\n"
  local files=(
    ".vscode/settings.json"
    ".vscode/tasks.json"
    ".vscode/commit-message-editor.json"
    ".devcontainer/devcontainer.json"
    ".pre-commit-config.yaml"
    ".gitmessage.txt"
  )
  for f in "${files[@]}"; do
    [[ -f "${f}" ]] \
      && ok "${f}" \
      || fail "${f} missing — run: /path/to/onboarding-setup/project-devcontainer.sh"
  done
}

# --- main ---

main() {
  load_state
  select_python_path
  deploy_vscode_settings
  deploy_devcontainer
  deploy_commit_editor_config
  deploy_tasks
  deploy_git_configs
  info "Done. Commit these files to your repo so all devs get them on clone:"
  printf "  .vscode/\n  .devcontainer/\n  .pre-commit-config.yaml\n  .gitmessage.txt\n"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
