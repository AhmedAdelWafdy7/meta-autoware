# Core plus simulation and devtools, for dev images
DESCRIPTION = "Autoware core plus simulation and devtools, dev images only"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    packagegroup-autoware-core \
    packagegroup-autoware-simulation \
    packagegroup-autoware-devtools \
"
