# Step 2 — Git + GitHub

## What this does

- Installs git and the GitHub CLI (`gh`)
- Prompts for your name and email for commit attribution
- Runs `gh auth login --git-protocol ssh` — opens your browser, generates an SSH key, and uploads it to GitHub automatically
- Configures SSH commit signing so your commits are verified on GitHub

## Why `gh` instead of just git

The GitHub CLI adds commands that plain git doesn't have:

- `gh pr create / merge / checkout` — pull request workflows without leaving the terminal
- `gh repo clone` — clones with auth baked in
- `gh run watch` — monitor GitHub Actions runs
- `gh issue` — create and manage issues

## How SSH commit signing works

After this step, git is configured to sign commits using your SSH key (`gpg.format = ssh`). GitHub shows a "Verified" badge on signed commits. This uses the same key as your SSH authentication — no separate GPG key needed.

## Useful commands

```bash
gh auth status         # check authentication
gh auth login          # re-authenticate if needed
git config --list      # verify git config
```
