require ${COREBASE}/meta/recipes-core/images/core-image-minimal.bb

SUMMARY = "Autoware dev image: core-image-autoware plus simulation and devtools"
DESCRIPTION = "${SUMMARY}. Not for production."
LICENSE = "MIT"

inherit ros_distro_${ROS_DISTRO}
inherit ${ROS_DISTRO_TYPE}_image

# Passwordless root login
EXTRA_IMAGE_FEATURES += "debug-tweaks"

IMAGE_INSTALL:append = " \
    ros-core \
    packagegroup-autoware-full \
"
