# Step 3 — Podman

## What this does

- Installs Podman via Homebrew
- Initializes and starts a Podman machine (the Linux VM that runs containers on macOS) with team-recommended CPU and memory resources
- Logs in to GitHub Container Registry (`ghcr.io`) using your GitHub credentials from step 2
- Configures registry search order (`us-central1-docker.pkg.dev`, `ghcr.io`, `docker.io`) inside the Podman VM

## What is Podman

Podman is a Docker-compatible container runtime. We use it instead of Docker Desktop. It runs rootless by default, which is more secure, and doesn't require a paid license.

All `docker` commands work with Podman — you can alias `docker=podman` or use `podman` directly.

## Container registries

After setup you will have access to:

- **GitHub Container Registry (GHCR)** — `ghcr.io` — authenticated via GitHub CLI (step 2)
- **GCP Artifact Registry** — `us-central1-docker.pkg.dev` — authenticated via GCP CLI (step 1)

## Useful commands

```bash
podman machine list       # check machine status
podman machine start      # start the machine if stopped
podman ps                 # list running containers
podman images             # list local images
```
