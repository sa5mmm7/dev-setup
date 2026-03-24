#!/usr/bin/env bash
set -euo pipefail

DOCTOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONBOARDING_ROOT="${ONBOARDING_ROOT:-$(cd "${DOCTOR_DIR}/.." && pwd)}"
export ONBOARDING_ROOT

# shellcheck source=scripts/lib.sh disable=SC1091
source "${DOCTOR_DIR}/scripts/lib.sh"

# Source each step to get their check functions (BASH_SOURCE guards prevent main from running)
# shellcheck disable=SC1091
source "${DOCTOR_DIR}/scripts/01-gcp/run.sh"
# shellcheck disable=SC1091
source "${DOCTOR_DIR}/scripts/02-git/run.sh"
# shellcheck disable=SC1091
source "${DOCTOR_DIR}/scripts/03-podman/run.sh"
# shellcheck disable=SC1091
source "${DOCTOR_DIR}/scripts/04-python/run.sh"
# shellcheck disable=SC1091
source "${DOCTOR_DIR}/scripts/05-vscode/run.sh"
# shellcheck disable=SC1091
source "${ONBOARDING_ROOT}/project-devcontainer.sh"

# --- color support ---
if [[ -t 1 ]]; then
  BOLD='\033[1m'
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  BOLD='' GREEN='' RED='' NC=''
fi

ISSUES=()

check_wsl() {
  printf "\n🔍 WSL2 environment\n"
  if grep -qiF "wsl" /proc/version 2>/dev/null || grep -qiF "microsoft" /proc/version 2>/dev/null; then
    ok "Running inside WSL2"
  else
    fail "Not running inside WSL2 — these scripts are intended for WSL2 only"
  fi
  check_command apt-get \
    && ok "apt-get available" \
    || fail "apt-get not found — requires a Debian/Ubuntu-based WSL2 distribution"
}

check_backups() {
  local baks=()
  while IFS= read -r f; do baks+=("${f}"); done \
    < <(find . -name "*.bak" ! -path "*/.git/*" 2>/dev/null | sort)
  if [[ ${#baks[@]} -gt 0 ]]; then
    printf "\n🔍 Backups\n"
    note "${#baks[@]} backup(s) available — run with --revert to restore:"
    for b in "${baks[@]}"; do
      printf "    %s\n" "${b}"
    done
  fi
}

print_summary() {
  printf "\n${BOLD}========================================${NC}\n"
  if [[ ${#ISSUES[@]} -eq 0 ]]; then
    printf "${GREEN}${BOLD}All checks passed.${NC}\n"
  else
    printf "${RED}${BOLD}%d issue(s) found:${NC}\n" "${#ISSUES[@]}"
    for issue in "${ISSUES[@]}"; do
      printf "  ❌ %s\n" "${issue}"
    done
  fi
  printf "${BOLD}========================================${NC}\n\n"
}

# --- revert ---

revert_backups() {
  local baks=()
  while IFS= read -r f; do baks+=("${f}"); done \
    < <(find . -name "*.bak" ! -path "*/.git/*" 2>/dev/null | sort)

  if [[ ${#baks[@]} -eq 0 ]]; then
    info "No backup files found."
    exit 0
  fi

  printf "\nSelect backup to restore:\n\n"
  select b in "${baks[@]}" "Restore all" "Cancel"; do
    case ${REPLY} in
      $((${#baks[@]} + 1)))
        for f in "${baks[@]}"; do
          dest="${f%.bak}"
          cp "${f}" "${dest}"
          rm "${f}"
          info "Restored: ${dest}"
        done
        break;;
      $((${#baks[@]} + 2)))
        info "Cancelled."
        break;;
      *)
        if [[ -n "${b}" ]]; then
          dest="${b%.bak}"
          cp "${b}" "${dest}"
          rm "${b}"
          info "Restored: ${dest}"
          break
        else
          echo "Invalid choice"
        fi;;
    esac
  done
}

# --- main ---

case "${1:-check}" in
  --revert)
    revert_backups
    ;;
  check|*)
    printf "\n${BOLD}Onboarding Doctor${NC}\n"
    check_wsl
    check_gcp
    check_git
    check_podman
    check_python
    check_vscode
    check_project_files
    check_backups
    print_summary
    ;;
esac
