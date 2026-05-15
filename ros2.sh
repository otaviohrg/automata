#!/usr/bin/env bash
set -e

xhost +local:docker >/dev/null 2>&1 || true

docker compose run --rm helix-base bash -lc "
  source /opt/ros/jazzy/setup.bash
  if [ -f /ros2_ws/install/setup.bash ]; then
    source /ros2_ws/install/setup.bash
  fi
  exec bash
"
