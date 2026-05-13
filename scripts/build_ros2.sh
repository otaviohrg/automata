#!/usr/bin/env bash
# scripts/build_ros2.sh
# Builds the ROS2 workspace and patches ament_prefix_path for all packages.
# Workaround for ament_cmake not generating ament_prefix_path.dsv correctly
# in this container environment.
# Usage (from inside the container):
#   bash /workspace/scripts/build_ros2.sh

set -eo pipefail

INSTALL_BASE="/ros2_ws/install"
BUILD_BASE="/tmp/colcon_build"
SRC_BASE="/workspace/ros2_ws/src"

echo "[build_ros2] sourcing ROS2..."
source /opt/ros/jazzy/setup.bash

echo "[build_ros2] running colcon build..."
colcon build \
  --base-paths "$SRC_BASE" \
  --install-base "$INSTALL_BASE" \
  --build-base "$BUILD_BASE" \
  --cmake-args -DCMAKE_BUILD_TYPE=Release

echo "[build_ros2] patching ament_prefix_path for all packages..."
for pkg_dir in "$INSTALL_BASE"/*/; do
  pkg_name=$(basename "$pkg_dir")
  share_dir="$pkg_dir/share/$pkg_name"
  package_dsv="$share_dir/package.dsv"
  env_dir="$share_dir/environment"
  env_dsv="$env_dir/ament_prefix_path.dsv"

  # Skip if package.dsv does not exist
  [[ -f "$package_dsv" ]] || continue

  # Skip if already patched
  if grep -q "ament_prefix_path" "$package_dsv"; then
    echo "  [skip] $pkg_name — already patched"
    continue
  fi

  # Create environment directory if missing
  mkdir -p "$env_dir"

  # Write the ament_prefix_path.dsv with the correct install path
  echo "prepend-non-duplicate;AMENT_PREFIX_PATH;$pkg_dir" > "$env_dsv"

  # Register it in package.dsv
  echo "source;share/$pkg_name/environment/ament_prefix_path.dsv" >> "$package_dsv"

  echo "  [patched] $pkg_name"
done

echo "[build_ros2] done — sourcing workspace..."
source "$INSTALL_BASE/setup.bash"

#echo "[build_ros2] packages available:"
#ros2 pkg list | grep -v "^/" || true
