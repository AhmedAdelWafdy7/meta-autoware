#!/usr/bin/env bash
# Run ros-mash against one Autoware tag or commit SHA. Starts from a clean workspace
# each time, so the output is reproducible. Runs natively when the host's Ubuntu
# matches the ROS distro, otherwise in a ros:<distro> container (docker or podman).
#
# Usage: tools/run-mash.sh <core|universe> <autoware_tag> <ros_distro>
#   core      only the "core" group of repositories/autoware.repos
#   universe  the full manifest
#
# Output: results/<mode>-<tag>/
set -euo pipefail

MODE="${1:?usage: $0 <core|universe> <autoware_tag> <ros_distro>}"
case "$MODE" in
  core|universe) ;;
  *) echo "usage: $0 <core|universe> <autoware_tag> <ros_distro>" >&2; exit 1 ;;
esac

AUTOWARE_TAG="${2:?usage: $0 <core|universe> <autoware_tag> <ros_distro>}"
ROS_DISTRO="${3:?usage: $0 <core|universe> <autoware_tag> <ros_distro>}"

AUTOWARE_REPO_URL="https://github.com/autowarefoundation/autoware.git"

# ls-remote only knows refs, so fall back to a shallow fetch for a commit SHA
if ! git ls-remote --tags --exit-code \
    "$AUTOWARE_REPO_URL" "refs/tags/${AUTOWARE_TAG}" \
    >/dev/null 2>&1; then
  TMP_REF_CHECK="$(mktemp -d)"
  if ! { git init -q "$TMP_REF_CHECK" \
      && git -C "$TMP_REF_CHECK" fetch -q --depth 1 "$AUTOWARE_REPO_URL" "$AUTOWARE_TAG" >/dev/null 2>&1; }; then
    rm -rf "$TMP_REF_CHECK"
    echo "error: '${AUTOWARE_TAG}' is not a tag or reachable commit in autowarefoundation/autoware" >&2
    exit 1
  fi
  rm -rf "$TMP_REF_CHECK"
fi

AUTOWARE_REPOS_URL="https://raw.githubusercontent.com/autowarefoundation/autoware/${AUTOWARE_TAG}/repositories/autoware.repos"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tools/mash-pins.sh
. "$REPO_ROOT/tools/mash-pins.sh"
RESULTS_DIR="$REPO_ROOT/results/${MODE}-${AUTOWARE_TAG}"
mkdir -p "$RESULTS_DIR"

# Ubuntu codename with official apt packages per ROS distro; anything else uses a container
declare -A ROS_DISTRO_CODENAME=(
  [jazzy]=noble
  [kilted]=noble
  [rolling]=noble
  [humble]=jammy
  [iron]=jammy
)

# Quoted heredoc: variables expand in whichever shell runs it, host or container
read -r -d '' WORKLOAD <<'SCRIPT' || true
set -e -o pipefail
export DEBIAN_FRONTEND=noninteractive

# root in the container, sudo on a native host
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO=sudo
fi

if ! command -v curl >/dev/null 2>&1 || ! command -v pip3 >/dev/null 2>&1; then
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq --no-install-recommends \
    curl gnupg2 ca-certificates python3-pip >/dev/null
fi

if [ ! -d "/opt/ros/$ROS_DISTRO" ]; then
  echo "ROS 2 $ROS_DISTRO not found -- installing..." >&2
  $SUDO curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $VERSION_CODENAME main" \
    | $SUDO tee /etc/apt/sources.list.d/ros2.list >/dev/null
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq --no-install-recommends \
    "ros-$ROS_DISTRO-ros-base" python3-colcon-common-extensions python3-vcstool \
    python3-rosdep python3-pip >/dev/null
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

eval "$MASH_SETUP"

curl -sL "$AUTOWARE_REPOS_URL" -o "$WORKDIR/autoware.repos"

if [ "$MODE" = "core" ]; then
  python3 - "$WORKDIR/autoware.repos" "$WORKDIR/mash-input.repos" <<'PYEOF'
import sys
import yaml
src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    data = yaml.safe_load(f)
data["repositories"] = {
    k: v for k, v in data["repositories"].items() if k.startswith("core/")
}
with open(dst, "w") as f:
    yaml.safe_dump(data, f)
PYEOF
else
  cp "$WORKDIR/autoware.repos" "$WORKDIR/mash-input.repos"
fi

mkdir -p "$WORKDIR/ws/src"
cd "$WORKDIR/ws"
vcs import --recursive src < "$WORKDIR/mash-input.repos" > "$WORKDIR/vcs-import.log" 2>&1

source "/opt/ros/$ROS_DISTRO/setup.bash"
mash --rosdistro "$ROS_DISTRO" > "$WORKDIR/mash.log" 2>&1 || true

cp "$WORKDIR/mash-input.repos" "$OUTPUT_DIR/input.repos"
cp "$WORKDIR/vcs-import.log" "$OUTPUT_DIR/"
cp "$WORKDIR/mash.log" "$OUTPUT_DIR/"
rm -rf "$OUTPUT_DIR/build_mash"
cp -r build_mash "$OUTPUT_DIR/" 2>/dev/null || true
SCRIPT

RUN_NATIVE=false
if [ -f /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [ "${ROS_DISTRO_CODENAME[$ROS_DISTRO]:-}" = "${VERSION_CODENAME:-}" ]; then
    RUN_NATIVE=true
  fi
fi

if [ "$RUN_NATIVE" = true ]; then
  echo "Host codename matches $ROS_DISTRO's native apt support -- running natively, no container." >&2
  AUTOWARE_REPOS_URL="$AUTOWARE_REPOS_URL" MODE="$MODE" ROS_DISTRO="$ROS_DISTRO" OUTPUT_DIR="$RESULTS_DIR" \
    ROS_MASH_VERSION="$ROS_MASH_VERSION" ROSDISTRO_SHA="$ROSDISTRO_SHA" MASH_SETUP="$MASH_SETUP" \
    bash -c "$WORKLOAD"
else
  if [ -z "${CONTAINER_RUNTIME:-}" ]; then
    if command -v docker >/dev/null 2>&1; then
      CONTAINER_RUNTIME=docker
    elif command -v podman >/dev/null 2>&1; then
      CONTAINER_RUNTIME=podman
    else
      echo "error: host doesn't natively support $ROS_DISTRO and no container runtime found (need docker or podman)" >&2
      exit 1
    fi
  fi
  if [ "$ROS_DISTRO" != jazzy ]; then
    echo "error: tools/mash-pins.sh pins a container image for jazzy only" >&2
    exit 1
  fi
  echo "Running inside $ROS_IMAGE ($CONTAINER_RUNTIME)." >&2
  "$CONTAINER_RUNTIME" run --rm \
    -v "$RESULTS_DIR:/results" \
    -e AUTOWARE_REPOS_URL="$AUTOWARE_REPOS_URL" \
    -e MODE="$MODE" \
    -e ROS_DISTRO="$ROS_DISTRO" \
    -e OUTPUT_DIR="/results" \
    -e ROS_MASH_VERSION="$ROS_MASH_VERSION" \
    -e ROSDISTRO_SHA="$ROSDISTRO_SHA" \
    -e MASH_SETUP="$MASH_SETUP" \
    "$ROS_IMAGE" \
    bash -c "$WORKLOAD"
fi

echo "Done. Results in $RESULTS_DIR"
