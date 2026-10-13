# Tier 1 functional group, names no machine or vendor
DESCRIPTION = "Autoware vehicle: Generic vehicle interface, description and info packages"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    autoware-core-vehicle \
    autoware-learning-based-vehicle-model \
    autoware-sample-vehicle-description \
    autoware-vehicle-info-utils \
    autoware-vehicle-velocity-converter \
    awsim-labs-vehicle-description \
    awsim-labs-vehicle-launch \
    sample-vehicle-description \
    sample-vehicle-launch \
    tier4-vehicle-launch \
"
