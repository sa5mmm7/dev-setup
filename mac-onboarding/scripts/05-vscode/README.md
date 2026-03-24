# Step 5 — VS Code

## What this does

- Installs VS Code via Homebrew
- Installs extensions for Python, linting, Jupyter, Dev Containers, Git, and GCP
- Prompts to select your default Python interpreter
- Deploys workspace config, VS Code settings, devcontainer setup, and pre-commit hooks

## Extensions installed

| Extension | Purpose |
| --- | --- |
| Python, Pylance | Core Python language support |
| Black | Formatting |
| Ruff | Linting |
| Jupyter | Notebook support |
| YAML | YAML editing |
| Dev Containers | Reopen projects inside Podman containers |
| Dataform LSP | Dataform/SQLX language support |
| GitLens | Enhanced git history and blame |
| GitHub Pull Requests | PR workflows inside VS Code |
| Commit Message Editor | Guided conventional commits |
| Cloud Code | GCP integration inside VS Code |

## Workspace vs user settings

This step writes **workspace-level** settings (`.vscode/settings.json`). These apply only to the current project and take precedence over your personal user settings, so your other projects are unaffected.

## Tasks

Runnable actions are available via `Terminal > Run Task` or `Cmd+Shift+P > Run Task`:

| Task | What it does |
| --- | --- |
| Ruff: Lint | Check for linting issues |
| Ruff: Fix | Auto-fix linting issues |
| Pre-commit: Run all hooks | Run all pre-commit checks across all files |
| Podman: Build | Build the project Dockerfile |
| Podman: Build Dev | Build the Dockerfile.dev |
| Podman: Install sub-project requirements | Install requirements.txt from subdirectories |
| Project: Setup dev container + VS Code config | Run project-devcontainer for the current repo |
| Python: Switch version | Pick a pyenv version and set it for the current project |

After switching Python version, reload the VS Code window (`Cmd+Shift+P > Reload Window`) to pick up the change.

## Dev containers

The `.devcontainer/` folder lets you run your code inside a Podman container. Run `project-devcontainer` from any repo root to set one up, then `Cmd+Shift+P > Dev Containers: Reopen in Container`.

If a `requirements.txt` exists in the project root it will be installed automatically when the container starts.

## Commit signing

Commit signing is enabled automatically if step 2 was run. VS Code will sign commits using your SSH key.

## Useful commands

```bash
./run-onboarding.sh 5   # re-run this step if settings need resetting
code onboarding.code-workspace  # open the configured workspace
```
