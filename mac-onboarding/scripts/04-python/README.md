# Step 4 — Python

## What this does

- Installs pyenv via Homebrew
- Installs Python versions defined in `config/team.env` (currently 3.10.14 and 3.14.0)
- Appends `eval "$(pyenv init -)"` to `~/.zshrc`
- Private packages install automatically via `pip install git+https://github.com/MeowWolf/...` — authenticated by GitHub auth from step 2

## Why multiple Python versions

Our shared library **barklion** (`de-python-clients`) supports Python 3.9, 3.10, and 3.14. Different repos may pin to different versions. pyenv lets you switch between them per-project using a `.python-version` file.

## Setting a Python version for a project

```bash
cd your-repo
pyenv local 3.10.14   # writes a .python-version file
python --version      # confirms the active version
```

## Barklion (de-python-clients)

Barklion is our internal Python client library, hosted on GitHub. Install a specific version with:

```bash
pip install git+https://github.com/MeowWolf/de-python-clients@v0.17.1
```

Or pin it in `requirements.txt`:

```text
git+https://github.com/MeowWolf/de-python-clients@v0.17.1
```

Authentication is handled automatically by the GitHub credentials set up in step 2.

## Useful commands

```bash
pyenv versions         # list installed versions
pyenv global 3.14.0    # set global default
pyenv local 3.10.14    # set version for current directory
```
