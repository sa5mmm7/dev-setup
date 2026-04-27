# Windows Onboarding

Automated developer onboarding for Windows using WSL2.

## Prerequisites (manual steps)

Before running any scripts, WSL2 must be set up on the Windows machine:

1. Open PowerShell as Administrator
2. Run: `wsl --install`
3. Restart the machine
4. Open Ubuntu from the Start menu and complete the initial user setup
5. Run: `wsl --set-default-version 2`

After WSL2 is ready, clone this repo inside WSL2 and run from there.

## Running onboarding

Run the full setup:

```bash
./run-onboarding.sh
```

Run only the Git + GitHub step:

```bash
./run-onboarding.sh 2
```

## Differences from macOS

- `brew` → `apt`
- `pyenv` works identically inside WSL2
- Podman Desktop with WSL2 backend instead of macOS machine
- Dev container `runArgs`: `--userns=keep-id` instead of `--privileged`
- `~/.zshrc` → `~/.bashrc` (or `~/.zshrc` if zsh is installed)
