# Step 2 - Git + GitHub

This step mirrors `mac-onboarding/scripts/02-git/README.md`.

Windows/WSL2 differences:

- Installs git with `apt` instead of Homebrew
- Installs GitHub CLI from the official apt repository
- Runs GitHub auth and SSH commit signing inside WSL2
- Uses the Linux SSH key under `~/.ssh`
- Uploads the WSL2 SSH public key to GitHub as a signing key
