# macOS Onboarding

Run from this directory or use the root `run-onboarding.sh` which auto-detects macOS.

```bash
./run-onboarding.sh          # run all steps
./run-onboarding.sh 2        # re-run a single step
./run-onboarding.sh git      # same, by name

./onboarding-doctor.sh       # check what's set up and what's missing
./onboarding-doctor.sh --revert  # restore any backed-up config files
```

## Requirements

- macOS (Apple Silicon or Intel)
- Internet connection
- Steps are idempotent — safe to re-run if something fails

## Steps

1. **GCP** — gcloud CLI, auth, ADC, Artifact Registry
2. **Git** — git, gh CLI, SSH auth, commit signing
3. **Podman** — Podman machine, GHCR login
4. **Python** — pyenv, Python versions from `config/team.env`, Ruff
5. **VS Code** — install, extensions

## Notes

- After any step that modifies `~/.zshrc`, run `source ~/.zshrc` or open a new terminal
- `code` CLI must be installed via VS Code → Cmd+Shift+P → `Shell Command: Install 'code' command in PATH` before step 5
