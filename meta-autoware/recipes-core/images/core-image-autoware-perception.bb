require ${COREBASE}/meta/recipes-core/images/core-image-minimal.bb

SUMMARY = "Autoware image with perception (needs a GPU BSP)"
DESCRIPTION = "${SUMMARY}. Perception is empty unless DISTRO_FEATURES contains cuda."
LICENSE = "MIT"

inherit ros_distro_${ROS_DISTRO}
inherit ${ROS_DISTRO_TYPE}_image

IMAGE_INSTALL:append = " \
    ros-core \
    packagegroup-autoware-core \
    packagegroup-autoware-perception \
"
