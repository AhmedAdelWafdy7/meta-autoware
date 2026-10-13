# Launch packages used by autoware_launch's planning_simulator; their CUDA-only RDEPENDS are
# stripped in autoware-fixups.bbclass. tier4-planning-launch also needs the excluded
# autoware-path-optimizer, so this group doesn't build yet.
DESCRIPTION = "Planning simulator launch packages, demo only"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    tier4-planning-launch \
    tier4-control-launch \
"
