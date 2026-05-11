FROM automata-base:latest

ENV PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# PyTorch CUDA 12.6
RUN uv pip install \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu126

# ML / robotics tooling
RUN uv pip install \
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
