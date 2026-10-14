require ${COREBASE}/meta/recipes-core/images/core-image-minimal.bb

SUMMARY = "Minimal Autoware image: system, vehicle and control, GPU-free"
DESCRIPTION = "${SUMMARY}"
LICENSE = "MIT"

inherit ros_distro_${ROS_DISTRO}
inherit ${ROS_DISTRO_TYPE}_image

IMAGE_INSTALL:append = " \
    ros-core \
    packagegroup-autoware-system \
    packagegroup-autoware-vehicle \
    packagegroup-autoware-control \
"
