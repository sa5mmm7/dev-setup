#!/usr/bin/env bash
# Shared utilities — source this from each step script

# Derive repo root from lib.sh location (windows-onboarding/scripts/ → ../../ = repo root).
ONBOARDING_ROOT="${ONBOARDING_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export ONBOARDING_ROOT

# Load team-specific config (GCP project, Python versions, etc.)
if [[ ! -f "${ONBOARDING_ROOT}/config/team.env" ]]; then
  echo "[ERROR] config/team.env not found."
  echo "        Copy config/team.env.example to config/team.env and fill in your values:"
  echo "          cp ${ONBOARDING_ROOT}/config/team.env.example ${ONBOARDING_ROOT}/config/team.env"
  exit 1
fi
# shellcheck source=/dev/null
source "${ONBOARDING_ROOT}/config/team.env"

info()  { echo "[INFO] $*"; }
warn()  { echo "[WARN] $*"; }
error() { echo "[ERROR] $*"; exit 1; }
ok()    { printf "✅ %s\n" "$*"; }
fail()  { printf "❌ %s\n" "$*"; ISSUES+=("$*"); }
note()  { printf "⚠️  %s\n" "$*"; }

check_command() {
  command -v "${1}" >/dev/null 2>&1
}

require_command() {
  local cmd="${1}" hint="${2}"
  if ! check_command "${cmd}"; then
    error "'${cmd}' not found. ${hint}"
  fi
}

# Detect the shell profile file to use (~/.zshrc or ~/.bashrc).
shell_profile() {
  if [[ -n "${ZSH_VERSION:-}" ]] || [[ "${SHELL:-}" == */zsh ]]; then
    echo "${HOME}/.zshrc"
  else
    echo "${HOME}/.bashrc"
  fi
}

# shellcheck disable=SC2034  # used by run-onboarding.sh after sourcing lib.sh
ZSHRC_UPDATED=false

append_zshrc() {
  local line="${1}"
  local profile
  profile="$(shell_profile)"
  if grep -qxF "${line}" "${profile}" 2>/dev/null; then
    info "Already in ${profile}: ${line}"
    return 1
  else
    echo "${line}" >> "${profile}"
    info "Added to ${profile}: ${line}"
    ZSHRC_UPDATED=true
    return 0
  fi
}

# Install VS Code extensions listed in a step's vscode-extensions.txt, if code is available.
install_step_extensions() {
  local step_dir="${1}" force="${2:-}"
  if ! check_command code; then
    info "VS Code not installed — extensions will be installed in step 5."
    return
  fi
  local ext_file="${step_dir}/vscode-extensions.txt"
  [[ -f "${ext_file}" ]] || return
  local flags=()
  [[ "${force}" == "--force" ]] && flags=("--force")
  while IFS= read -r ext || [[ -n "${ext}" ]]; do
    [[ -z "${ext}" || "${ext}" =~ ^# ]] && continue
    info "Installing VS Code extension: ${ext}"
    code --install-extension "${ext}" "${flags[@]+"${flags[@]}"}" || warn "Could not install extension ${ext}"
  done < "${ext_file}"
}

# Back up a file if it already exists.
backup_if_exists() {
  local dest="${1}"
  if [[ -f "${dest}" ]]; then
    cp "${dest}" "${dest}.bak"
    warn "Existing file backed up: ${dest}.bak"
  fi
}

# Copy src to dest, backing up any existing file at dest first.
safe_deploy() {
  local src="${1}" dest="${2}"
  backup_if_exists "${dest}"
  cp "${src}" "${dest}"
}

# Write Podman container runtime settings to VS Code user settings (Windows-side).
# Called from step 3 (if VS Code is installed) and step 5 (as a fallback).
configure_vscode_for_podman() {
  if ! check_command code; then
    info "VS Code not installed yet — Podman user settings will be applied in step 5."
    return
  fi
  local appdata
  # shellcheck disable=SC2016  # $env:APPDATA is PowerShell syntax, not bash
  appdata="$(powershell.exe -Command '$env:APPDATA' 2>/dev/null | tr -d '\r\n')"
  if [[ -z "${appdata}" ]]; then
    warn "Could not determine Windows APPDATA path — skipping VS Code user settings."
    return
  fi
  local user_settings
  user_settings="$(wslpath "${appdata}")/Code/User/settings.json"
  if [[ ! -f "${user_settings}" ]]; then
    mkdir -p "$(dirname "${user_settings}")"
    echo '{}' > "${user_settings}"
  fi
  local user_tasks
  user_tasks="$(wslpath "${appdata}")/Code/User/tasks.json"
  local user_tasks_src="${ONBOARDING_ROOT}/config/vscode/user-tasks.json"
  if [[ -f "${user_tasks_src}" && ! -f "${user_tasks}" ]]; then
    cp "${user_tasks_src}" "${user_tasks}"
    info "Deployed VS Code user tasks."
  elif [[ -f "${user_tasks_src}" && -f "${user_tasks}" ]]; then
    python3 - "${user_tasks}" "${user_tasks_src}" <<'PYEOF'
import json, sys
dest_path, src_path = sys.argv[1], sys.argv[2]
with open(dest_path) as f:
    try: dest = json.load(f)
    except json.JSONDecodeError: dest = {"version": "2.0.0", "tasks": []}
with open(src_path) as f:
    src = json.load(f)
existing_labels = {t["label"] for t in dest.get("tasks", [])}
to_add = [t for t in src.get("tasks", []) if t["label"] not in existing_labels]
if to_add:
    dest.setdefault("tasks", []).extend(to_add)
    with open(dest_path, "w") as f:
        json.dump(dest, f, indent=2)
    print("[INFO] VS Code user tasks updated.")
else:
    print("[INFO] VS Code user tasks already configured.")
PYEOF
  fi
  python3 - "${user_settings}" <<'EOF'
import json, sys
path = sys.argv[1]
with open(path) as f:
    try:
        settings = json.load(f)
    except json.JSONDecodeError:
        settings = {}
scalar_changes = {
    "dev.containers.dockerPath": "podman",
    "containers.containerClient": "podman",
}
team_default_extensions = [
    "eamodio.gitlens",
    "adam-bender.commit-message-editor",
    "GitHub.vscode-pull-request-github",
    "github.vscode-github-actions",
]
updated = False
for k, v in scalar_changes.items():
    if settings.get(k) != v:
        settings[k] = v
        updated = True
# Merge team extensions into dev.containers.defaultExtensions without removing user's own
ext_key = "dev.containers.defaultExtensions"
existing = settings.get(ext_key, [])
to_add = [e for e in team_default_extensions if e not in existing]
if to_add:
    settings[ext_key] = existing + to_add
    updated = True
if updated:
    with open(path, "w") as f:
        json.dump(settings, f, indent=2)
    print("[INFO] VS Code user settings updated for Podman.")
else:
    print("[INFO] VS Code Podman settings already configured.")
EOF
}

ensure_apt() {
  if ! grep -qF "microsoft" /proc/version 2>/dev/null && ! grep -qiF "wsl" /proc/version 2>/dev/null; then
    error "This script must be run inside WSL2."
  fi
  if ! check_command apt-get; then
    error "apt-get not found. This script requires a Debian/Ubuntu-based WSL2 distribution."
  fi
  info "Updating apt package lists..."
  sudo apt-get update -qq
}
