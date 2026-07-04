# sd-webui-forge-docker

Auto-built Docker image for [SD WebUI Forge Classic (Neo)](https://github.com/Haoming02/sd-webui-forge-classic/tree/neo), targeting NVIDIA GPUs (CUDA 12.6 / RTX 3060).

Nightly GitHub Actions checks for new upstream releases and rebuilds + pushes to `ghcr.io/jonhearsch/sd-webui-forge` if there's anything new. Watchtower on Unraid picks it up automatically.

## Unraid setup

**Prerequisites:** Nvidia GPU plugin installed via Community Apps.

```bash
mkdir -p /mnt/user/appdata/sd-webui-forge/{models,output,extensions,config}
docker compose up -d
```

Open: `http://UNRAID-IP:7860`

First run will install remaining Python deps — takes a few minutes. Subsequent starts are fast.

## Volume mounts

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `.../models` | `/home/forge/sd-webui/models` | Checkpoints, VAE, LoRA, ControlNet |
| `.../output` | `/home/forge/sd-webui/output` | Generated images |
| `.../extensions` | `/home/forge/sd-webui/extensions` | User extensions |
| `.../config` | `/home/forge/sd-webui/config` | UI settings (persists across rebuilds) |

## Extra launch args

Set `COMMANDLINE_ARGS` in `docker-compose.yml`, e.g.:
```yaml
environment:
  - COMMANDLINE_ARGS=--medvram --xformers
```

## Manual trigger / force rebuild

Actions tab → **Build and Push Docker Image** → **Run workflow** → check **Force rebuild** to rebuild even if already on the latest release.

## Image tags

| Tag | Description |
|-----|-------------|
| `latest` | Most recent Forge Classic release |
| `2.x` | Pinned to a specific upstream release |
