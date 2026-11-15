# Inputs that decide what ros-mash generates, besides the Autoware manifest itself.
# Sourced by run-mash.sh and run-mash-devtools.sh. Change one only in its own commit.

# PyPI release
ROS_MASH_VERSION=0.1.0
# ros/rosdistro commit for rosdep keys and the distribution index
ROSDISTRO_SHA=de24d609dc1d37359d79a8aa4e5bee20c447e654
# used when the host is not the Ubuntu release the ROS distro targets
ROS_IMAGE=ros:jazzy@sha256:8eed0a4669bbf43ee331878a4c39bd8ebddea8e3312a58b4fae8edb14526b617

# Runs inside the workload, host or container, after WORKDIR is set: rosdep from
# ROSDISTRO_SHA in a private ROS_HOME, so neither the host's rosdep cache nor rosdistro
# master is used
read -r -d '' MASH_SETUP <<'SETUP' || true
export ROS_HOME="$WORKDIR/ros_home"
export ROSDEP_SOURCE_PATH="$ROS_HOME/sources.list.d"
export ROSDISTRO_INDEX_URL="https://raw.githubusercontent.com/ros/rosdistro/$ROSDISTRO_SHA/index-v4.yaml"
mkdir -p "$ROSDEP_SOURCE_PATH"
for f in base python ruby; do
  echo "yaml https://raw.githubusercontent.com/ros/rosdistro/$ROSDISTRO_SHA/rosdep/$f.yaml"
done > "$ROSDEP_SOURCE_PATH/20-default.list"
rosdep update --rosdistro "$ROS_DISTRO" >/dev/null
pip3 install --quiet --break-system-packages "ros-mash==$ROS_MASH_VERSION" colcon-common-extensions
SETUP
