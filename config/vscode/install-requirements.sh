#!/usr/bin/env bash
# Discover requirements.txt files across sub-projects and pip install the selected one.
# Run from within a dev container or active Python environment.

mapfile -t files < <(find . -name "requirements.txt" \
  ! -path "*/.venv/*" \
  ! -path "*/node_modules/*" \
  ! -path "*/.git/*" \
  ! -path "*/.devcontainer/*" \
  | sort)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "[WARN] No requirements.txt found in this project."
  exit 0
fi

printf "\nSelect requirements file to install:\n\n"
PS3="Choice: "
select f in "${files[@]}"; do
  if [[ -n "${f}" ]]; then
    printf "\nInstalling from %s...\n" "${f}"
    pip install -r "${f}"
    break
  else
    echo "Invalid choice — enter a number"
  fi
done
