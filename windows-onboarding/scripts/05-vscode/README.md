# Step 5 - VS Code

This step mirrors `mac-onboarding/scripts/05-vscode/README.md`.

Windows/WSL2 differences:

- Expects VS Code to be installed on Windows
- Uses the `code` command exposed inside WSL2 by VS Code Remote WSL
- Installs extensions through the WSL2-accessible `code` command
- Writes VS Code user settings to the Windows `%APPDATA%` Code profile
- Configures Podman settings for projects opened through Remote WSL
