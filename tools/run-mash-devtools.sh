#!/usr/bin/env bash
# Run ros-mash for ROS devtools packages outside autoware.repos (foxglove_bridge),
# which follow their own release cadence.
#
# Usage: tools/run-mash-devtools.sh <foxglove_bridge_tag>
#
# Output: results/devtools-<tag>/
set -euo pipefail

FOXGLOVE_TAG="${1:?usage: $0 <foxglove_bridge_tag>}"

FOXGLOVE_REPO_URL="https://github.com/foxglove/ros-foxglove-bridge.git"

if ! git ls-remote --tags --exit-code \
    "$FOXGLOVE_REPO_URL" "refs/tags/${FOXGLOVE_TAG}" \
    >/dev/null 2>&1; then
  echo "error: tag '${FOXGLOVE_TAG}' not found in foxglove/ros-foxglove-bridge" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tools/mash-pins.sh
. "$REPO_ROOT/tools/mash-pins.sh"
RESULTS_DIR="$REPO_ROOT/results/devtools-${FOXGLOVE_TAG}"
mkdir -p "$RESULTS_DIR"

read -r -d '' WORKLOAD <<'SCRIPT' || true
set -e -o pipefail
export DEBIAN_FRONTEND=noninteractive

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO=sudo
fi

if ! command -v curl >/dev/null 2>&1 || ! command -v pip3 >/dev/null 2>&1; then
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq --no-install-recommends \
    curl gnupg2 ca-certificates python3-pip >/dev/null
fi

if [ ! -d /opt/ros/jazzy ]; then
  echo "ROS 2 Jazzy not found -- installing..." >&2
  $SUDO curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $VERSION_CODENAME main" \
    | $SUDO tee /etc/apt/sources.list.d/ros2.list >/dev/null
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq --no-install-recommends \
    ros-jazzy-ros-base python3-colcon-common-extensions python3-vcstool \
    python3-rosdep python3-pip >/dev/null
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

eval "$MASH_SETUP"

cat > "$WORKDIR/mash-input.repos" <<EOF
repositories:
  foxglove_bridge:
    type: git
    url: $FOXGLOVE_REPO_URL
    version: $FOXGLOVE_TAG
EOF

mkdir -p "$WORKDIR/ws/src"
cd "$WORKDIR/ws"
vcs import --recursive src < "$WORKDIR/mash-input.repos" > "$WORKDIR/vcs-import.log" 2>&1

source /opt/ros/jazzy/setup.bash
mash --rosdistro jazzy > "$WORKDIR/mash.log" 2>&1 || true

cp "$WORKDIR/mash-input.repos" "$OUTPUT_DIR/input.repos"
cp "$WORKDIR/vcs-import.log" "$OUTPUT_DIR/"
cp "$WORKDIR/mash.log" "$OUTPUT_DIR/"
rm -rf "$OUTPUT_DIR/build_mash"
cp -r build_mash "$OUTPUT_DIR/" 2>/dev/null || true
SCRIPT

IS_NOBLE=false
if [ -f /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  [ "${VERSION_CODENAME:-}" = "noble" ] && IS_NOBLE=true
fi

if [ "$IS_NOBLE" = true ]; then
  echo "Ubuntu 24.04 (Noble) detected -- running natively, no container." >&2
  FOXGLOVE_REPO_URL="$FOXGLOVE_REPO_URL" FOXGLOVE_TAG="$FOXGLOVE_TAG" OUTPUT_DIR="$RESULTS_DIR" \
    ROS_DISTRO=jazzy ROS_MASH_VERSION="$ROS_MASH_VERSION" ROSDISTRO_SHA="$ROSDISTRO_SHA" \
    MASH_SETUP="$MASH_SETUP" bash -c "$WORKLOAD"
else
  if [ -z "${CONTAINER_RUNTIME:-}" ]; then
    if command -v docker >/dev/null 2>&1; then
      CONTAINER_RUNTIME=docker
    elif command -v podman >/dev/null 2>&1; then
      CONTAINER_RUNTIME=podman
    else
      echo "error: not on Ubuntu 24.04 and no container runtime found (need docker or podman)" >&2
      exit 1
    fi
  fi
  echo "Not Ubuntu 24.04 -- running inside $ROS_IMAGE ($CONTAINER_RUNTIME)." >&2
  "$CONTAINER_RUNTIME" run --rm \
    -v "$RESULTS_DIR:/results" \
    -e FOXGLOVE_REPO_URL="$FOXGLOVE_REPO_URL" \
    -e FOXGLOVE_TAG="$FOXGLOVE_TAG" \
    -e OUTPUT_DIR="/results" \
    -e ROS_DISTRO=jazzy \
    -e ROS_MASH_VERSION="$ROS_MASH_VERSION" \
    -e ROSDISTRO_SHA="$ROSDISTRO_SHA" \
    -e MASH_SETUP="$MASH_SETUP" \
    "$ROS_IMAGE" \
    bash -c "$WORKLOAD"
fi

echo "Done. Results in $RESULTS_DIR"
