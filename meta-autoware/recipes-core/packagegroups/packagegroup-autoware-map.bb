# Tier 1 functional group, names no machine or vendor
DESCRIPTION = "Autoware map: Map loading and lanelet2"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    autoware-core-map \
    autoware-grid-map-utils \
    autoware-lanelet2-extension \
    autoware-lanelet2-extension-python \
    autoware-lanelet2-map-visualizer \
    autoware-lanelet2-utils \
    autoware-map-based-prediction \
    autoware-map-height-fitter \
    autoware-map-loader \
    autoware-map-projection-loader \
    autoware-map-tf-generator \
    autoware-traffic-light-map-based-detector \
    tier4-map-launch \
"
