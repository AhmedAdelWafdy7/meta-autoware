# Production GPU-free set; perception, simulation and devtools stay out
DESCRIPTION = "Autoware core: all GPU-free functional groups"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    packagegroup-autoware-msgs \
    packagegroup-autoware-common \
    packagegroup-autoware-system \
    packagegroup-autoware-vehicle \
    packagegroup-autoware-control \
    packagegroup-autoware-localization \
    packagegroup-autoware-planning \
    packagegroup-autoware-map \
    packagegroup-autoware-sensing \
"
