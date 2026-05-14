FROM ghcr.io/otaviohrg/helix-base:latest

ENV PYTHONUNBUFFERED=1
ENV UV_HTTP_TIMEOUT=600

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# PyTorch stable CUDA 12.4 stack
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install \
    torch==2.6.0 \
    torchvision==0.21.0 \
    torchaudio==2.6.0 \
    --index-url https://download.pytorch.org/whl/cu124

# ML / robotics tooling
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install \
    wandb \
    mlflow \
    onnx \
    onnxruntime-gpu \
    transformers \
    datasets \
    accelerate \
    diffusers \
    safetensors \
    opencv-python \
    pillow \
    scikit-learn \
    pandas \
    jupyterlab \
    tensorboard \
    einops \
    timm

WORKDIR /workspace
