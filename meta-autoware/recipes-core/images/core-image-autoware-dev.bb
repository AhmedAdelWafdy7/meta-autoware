require ${COREBASE}/meta/recipes-core/images/core-image-minimal.bb

SUMMARY = "Autoware dev image: core-image-autoware plus simulation and devtools"
DESCRIPTION = "${SUMMARY}. Not for production."
LICENSE = "MIT"

inherit ros_distro_${ROS_DISTRO}
inherit ${ROS_DISTRO_TYPE}_image

# Passwordless root login; wrynose dropped debug-tweaks, these three replace it
EXTRA_IMAGE_FEATURES += "allow-empty-password allow-root-login empty-root-password"

IMAGE_INSTALL:append = " \
    ros-core \
    packagegroup-autoware-full \
"
