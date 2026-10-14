# Tier 1 functional group, names no machine or vendor
DESCRIPTION = "Autoware sensing: Generic driver frameworks and interfaces, no vendor drivers"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    autoware-awsim-sensor-kit-description \
    autoware-core-sensing \
    autoware-crop-box-filter \
    autoware-euclidean-cluster-object-detector \
    autoware-gnss-poser \
    autoware-ground-filter \
    autoware-image-diagnostics \
    autoware-image-object-locator \
    autoware-image-transport-decompressor \
    autoware-imu-corrector \
    autoware-radar-fusion-to-detected-object \
    autoware-radar-object-tracker \
    autoware-radar-objects-adapter \
    autoware-radar-scan-to-pointcloud2 \
    autoware-radar-static-pointcloud-filter \
    autoware-radar-threshold-filter \
    autoware-radar-tracks-noise-filter \
    autoware-sample-sensor-kit-description \
    autoware-traffic-light-multi-camera-fusion \
    awsim-labs-sensor-kit-description \
    awsim-sensor-kit-description \
    boost-io-context \
    boost-serial-driver \
    boost-tcp-driver \
    boost-udp-driver \
    carla-sensor-kit-description \
    carla-sensor-kit-launch \
    common-awsim-labs-sensor-launch \
    nebula-core-common \
    nebula-core-hw-interfaces \
    nebula-core-ros \
    pointcloud-to-laserscan \
    ros2-socketcan \
    ros2agnocast \
    ros2agnocast-discovery-agent \
    sample-sensor-kit-description \
    single-lidar-sensor-kit-description \
    tier4-sensing-launch \
"
