# Step 1 - GCP CLI

This step mirrors `mac-onboarding/scripts/01-gcp/README.md`.

Windows/WSL2 differences:

- Installs Google Cloud CLI with `apt` instead of Homebrew
- Adds the Google Cloud apt repository and keyring inside WSL2
- Configures shell completion in your WSL2 shell profile
- Uses Linux paths under WSL2 for `gcloud` config and Application Default Credentials
