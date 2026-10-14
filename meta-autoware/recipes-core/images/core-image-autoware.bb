require ${COREBASE}/meta/recipes-core/images/core-image-minimal.bb

SUMMARY = "Autoware image: packagegroup-autoware-core, GPU-free"
DESCRIPTION = "${SUMMARY}"
LICENSE = "MIT"

inherit ros_distro_${ROS_DISTRO}
inherit ${ROS_DISTRO_TYPE}_image

IMAGE_INSTALL:append = " \
    ros-core \
    packagegroup-autoware-core \
"
