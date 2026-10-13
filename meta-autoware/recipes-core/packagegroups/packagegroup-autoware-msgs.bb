# Tier 1 functional group, names no machine or vendor
DESCRIPTION = "Autoware msgs: Message/interface packages (near-zero deps)"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    agnocast-cie-config-msgs \
    autoware-adapi-v1-msgs \
    autoware-adapi-version-msgs \
    autoware-common-msgs \
    autoware-component-interface-specs \
    autoware-component-interface-specs-universe \
    autoware-control-msgs \
    autoware-internal-debug-msgs \
    autoware-internal-localization-msgs \
    autoware-internal-metric-msgs \
    autoware-internal-msgs \
    autoware-internal-perception-msgs \
    autoware-internal-planning-msgs \
    autoware-localization-msgs \
    autoware-map-msgs \
    autoware-msgs \
    autoware-perception-msgs \
    autoware-planning-msgs \
    autoware-radar-tracks-msgs-converter \
    autoware-sensing-msgs \
    autoware-simulation-msgs \
    autoware-system-msgs \
    autoware-v2x-msgs \
    autoware-vehicle-msgs \
    eagleye-msgs \
    nebula-msgs \
    robosense-msgs \
    ros2-socketcan-msgs \
    ros2agnocast-discovery-msgs \
    rtklib-msgs \
    rviz-2d-overlay-msgs \
    sync-tooling-msgs \
    tier4-api-msgs \
    tier4-auto-msgs-converter \
    tier4-control-msgs \
    tier4-debug-msgs \
    tier4-external-api-msgs \
    tier4-hmi-msgs \
    tier4-localization-msgs \
    tier4-map-msgs \
    tier4-metric-msgs \
    tier4-perception-msgs \
    tier4-planning-msgs \
    tier4-rtc-msgs \
    tier4-simulation-msgs \
    tier4-system-msgs \
    tier4-v2x-msgs \
    tier4-vehicle-msgs \
"
