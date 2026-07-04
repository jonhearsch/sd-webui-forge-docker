# syntax=docker/dockerfile:1
# SD WebUI Forge Classic (Neo) | NVIDIA GPU
# Adapted from: https://github.com/Haoming02/sd-webui-forge-classic/tree/neo/docker

ARG CUDA_VERSION=12.6.3
FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu22.04

ARG FORGE_VERSION=neo
ARG TORCH_INDEX=cu126

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_PYTHON_DOWNLOADS=automatic \
    UV_NO_CACHE=1 \
    TORCH_INDEX_URL=https://download.pytorch.org/whl/${TORCH_INDEX}

# uv — fast Python package manager
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        ffmpeg \
        git \
        libgl1 \
        libglib2.0-0 \
        libgomp1 \
        libtcmalloc-minimal4 \
        pciutils \
    && rm -rf /var/lib/apt/lists/*

# UID 99 / GID 100 = nobody:users — matches Unraid default share permissions
RUN groupadd -g 100 users 2>/dev/null || true \
    && useradd -u 99 -g 100 -d /home/forge -m -s /bin/bash forge

WORKDIR /home/forge/sd-webui

# Clone the pinned release tag
RUN git clone --branch "${FORGE_VERSION}" --depth 1 --filter blob:none \
        https://github.com/Haoming02/sd-webui-forge-classic.git . \
    && chown -R 99:100 /home/forge

USER forge

# Python 3.13 venv via uv
RUN uv venv venv --python 3.13 --seed

ENV VIRTUAL_ENV="/home/forge/sd-webui/venv" \
    PATH="/home/forge/sd-webui/venv/bin:$PATH" \
    PYTHON="/home/forge/sd-webui/venv/bin/python3.13"

# Pre-install PyTorch so first-run doesn't have to fetch it
RUN uv pip install torch torchvision \
    --index-url "https://download.pytorch.org/whl/${TORCH_INDEX}"

# Persistent data directories (bind-mounted from host at runtime)
RUN mkdir -p \
        models/Stable-diffusion \
        models/VAE \
        models/Lora \
        models/ControlNet \
        extensions \
        config \
        output

COPY --chown=99:100 entrypoint.sh /home/forge/sd-webui/entrypoint.sh
RUN chmod +x /home/forge/sd-webui/entrypoint.sh

EXPOSE 7860

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=15 \
    CMD curl -f http://localhost:7860/ || exit 1

ENTRYPOINT ["/home/forge/sd-webui/entrypoint.sh"]
