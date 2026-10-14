# Simulator and dummy publishers, dev images only
DESCRIPTION = "Autoware simulation tools, dev images only"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    autoware-simple-planning-simulator \
    autoware-dummy-perception-publisher \
    autoware-dummy-traffic-light-publisher \
    autoware-dummy-diag-publisher \
    autoware-dummy-infrastructure \
    autoware-scenario-simulator-v2-adapter \
    autoware-vehicle-door-simulator \
    tier4-simulator-launch \
    autoware-fault-injection \
    autoware-carla-interface \
    tier4-system-launch \
    tier4-autoware-api-launch \
    autoware-system-designer \
    autoware-system-design-examples \
    autoware-universe-designs \
    autoware-sample-designs \
"
