# dev-setup

Automated developer onboarding for macOS and Windows (WSL2). Sets up GCP, Git, Podman, Python, and VS Code in one command.

## Quick start

This repo is the **public tooling layer**. Your team maintains a separate **private config repo** that contains a pre-filled `config/team.env` with your org's GCP project, registry, and other settings. New devs run this public repo first to get their tools, then apply team config from the private repo.

### Step 1 — Install tools (this repo)

**macOS (no git yet):**

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/dev-setup/main/bootstrap.sh | bash
```

**Windows** — WSL2 must be set up first. In PowerShell (as Administrator):

```powershell
wsl --install
```

Restart, open Ubuntu from the Start menu, then run inside WSL2:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/dev-setup/main/bootstrap.sh | bash
```

**Already have git:**

```bash
git clone https://github.com/YOUR_ORG/dev-setup.git ~/dev-setup
cd ~/dev-setup
cp config/team.env.example config/team.env
# Edit config/team.env with your team's values, then:
./run-onboarding.sh
```

### Step 2 — Apply team config (private repo)

Once tools are installed and you have GitHub access from step 1, clone your team's private config repo and re-run onboarding to apply team-specific settings:

```bash
git clone https://github.com/YOUR_ORG/your-private-config-repo.git ~/team-config
cd ~/team-config
./run-onboarding.sh
```

The private repo's `config/team.env` overrides defaults with your org's GCP project, Artifact Registry, Python versions, and Podman resource settings.

## Steps

| # | Name   | What it does                              |
|---|--------|-------------------------------------------|
| 1 | GCP    | gcloud CLI, auth, ADC, Artifact Registry  |
| 2 | Git    | git, gh CLI, SSH key + commit signing     |
| 3 | Podman | Podman machine, GHCR login                |
| 4 | Python | pyenv, Python versions, Ruff              |
| 5 | VS Code| install, extensions                       |

Run all steps or a single one:

```bash
./run-onboarding.sh        # all steps
./run-onboarding.sh 2      # step 2 only
./run-onboarding.sh git    # same, by name
```

## After onboarding

Check everything is set up correctly:

```bash
./mac-onboarding/onboarding-doctor.sh
```

Set up VS Code dev container config for a project repo:

```bash
cd /path/to/your-repo
project-devcontainer
```

This deploys `.vscode/`, `.devcontainer/`, `.pre-commit-config.yaml`, and `.gitmessage.txt` into the repo. Commit the results so every dev gets them on clone.

## Configuration

All team-specific values live in `config/team.env` (gitignored). Copy the example and fill in your values before running onboarding:

```bash
cp config/team.env.example config/team.env
```

## Requirements

- macOS (Apple Silicon or Intel), or Windows with WSL2
- Internet connection
- Steps are idempotent — safe to re-run if something fails

## File structure

```text
bootstrap.sh                  curl this on a new machine
run-onboarding.sh             OS-detecting entry point
project-devcontainer.sh       per-repo VS Code + dev container setup
config/
  team.env.example            copy to team.env and fill in your values
  vscode/                     settings, workspace, devcontainer templates
  git/                        pre-commit config, git message template
mac-onboarding/
  run-onboarding.sh
  onboarding-doctor.sh
  scripts/
    lib.sh
    01-gcp/
    02-git/
    03-podman/
    04-python/
    05-vscode/
windows-onboarding/
  run-onboarding.sh
  scripts/
    lib.sh
    01-gcp/
    02-git/
    03-podman/
    04-python/
    05-vscode/
```
