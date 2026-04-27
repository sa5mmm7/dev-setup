# Step 3 - Podman

This step mirrors `mac-onboarding/scripts/03-podman/README.md`.

Windows/WSL2 differences:

- Installs Podman with `apt` instead of Homebrew
- Runs Linux containers natively inside WSL2
- Does not create or start a `podman machine`
- Writes registry search config under `/etc/containers/registries.conf.d`
- Configures VS Code settings for the Windows-side Remote WSL workflow
