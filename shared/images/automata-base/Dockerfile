FROM osrf/ros:jazzy-desktop-full

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=jazzy
ENV MUJOCO_GL=egl
ENV PYTHONUNBUFFERED=1
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-pip \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    build-essential \
    cmake \
    ninja-build \
    git \
    curl \
    wget \
    pkg-config \
    libgl1 \
    libegl1 \
    libgles2 \
    libosmesa6 \
    libglvnd-dev \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libxcb1-dev \
    libxkbcommon-x11-0 \
    mesa-utils \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

ENV PATH="/root/.local/bin:/opt/venv/bin:$PATH"

# Create Python environment
RUN uv venv /opt/venv --python python3

# Install Python packages into the venv
RUN uv pip install \
    mujoco \
    numpy \
    scipy \
    matplotlib \
    pyopengl \
    glfw \
    imageio \
    gymnasium \
    gymnasium-robotics \
    catkin-pkg \
    grpcio \
    grpcio-tools \
    protobuf

RUN rosdep init || true && rosdep update || true

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc && \
    echo "source /opt/venv/bin/activate" >> /root/.bashrc

WORKDIR /workspace
