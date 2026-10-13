# Headless introspection: foxglove_bridge streams to Foxglove on a laptop, no Qt/X11 on target
DESCRIPTION = "foxglove_bridge and ros2 CLI tools, dev images only"
LICENSE = "MIT"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    foxglove-bridge \
    ros2bag \
    ros2topic \
    ros2node \
"
