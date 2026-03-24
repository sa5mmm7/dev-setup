# Step 1 — GCP CLI

## What this does

- Installs the Google Cloud SDK via Homebrew
- Runs `gcloud init` to authenticate and select a project
- Runs `gcloud auth application-default login` so local code can authenticate automatically (ADC)
- Sets default project and region/zone
- Adds the SDK to your `~/.zshrc`

## Why ADC matters

Application Default Credentials (ADC) lets Python code running locally authenticate with GCP services (BigQuery, Cloud Storage, Secret Manager, etc.) without any extra config. After running this step, libraries like `google-cloud-bigquery` will just work.

## Default project

Use `mw-etl-sandbox` as your default — it's the safe development environment.

## Default region/zone

`us-central1-f`

## Useful commands

```bash
gcloud auth list                         # see active accounts
gcloud config list                       # see current project/region
gcloud auth application-default revoke  # revoke ADC if needed
```
