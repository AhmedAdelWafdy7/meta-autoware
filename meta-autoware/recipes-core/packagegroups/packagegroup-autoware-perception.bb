# Empty unless a GPU BSP sets DISTRO_FEATURES:cuda; its packages are not synced into
# generated-recipes/ yet
DESCRIPTION = "Autoware perception, opt-in via DISTRO_FEATURES:cuda"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'cuda', 'autoware-perception-launch autoware-diffusion-planner', '', d)}"
