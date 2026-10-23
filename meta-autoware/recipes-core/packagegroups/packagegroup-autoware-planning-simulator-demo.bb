# Everything autoware_launch's planning_simulator.launch.xml starts, including the planner
# modules the default planning preset loads by name (tier4-planning-launch doesn't declare
# them). CUDA-only and otherwise unbuildable RDEPENDS are stripped in autoware-fixups.bbclass.
DESCRIPTION = "Autoware planning simulator, demo only"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    autoware-launch \
    tier4-map-launch \
    tier4-vehicle-launch \
    tier4-system-launch \
    tier4-planning-launch \
    tier4-control-launch \
    tier4-simulator-launch \
    tier4-perception-launch \
    tier4-autoware-api-launch \
    autoware-simple-planning-simulator \
    autoware-dummy-perception-publisher \
    autoware-path-sampler \
    autoware-path-smoother \
    autoware-motion-velocity-planner \
    autoware-motion-velocity-planner-common \
    autoware-motion-velocity-boundary-departure-prevention-module \
    autoware-motion-velocity-dynamic-obstacle-stop-module \
    autoware-motion-velocity-obstacle-cruise-module \
    autoware-motion-velocity-obstacle-slow-down-module \
    autoware-motion-velocity-obstacle-stop-module \
    autoware-motion-velocity-obstacle-velocity-limiter-module \
    autoware-motion-velocity-out-of-lane-module \
    autoware-motion-velocity-road-user-stop-module \
    autoware-motion-velocity-run-out-module \
    autoware-behavior-velocity-blind-spot-module \
    autoware-behavior-velocity-crosswalk-module \
    autoware-behavior-velocity-detection-area-module \
    autoware-behavior-velocity-intersection-module \
    autoware-behavior-velocity-no-stopping-area-module \
    autoware-behavior-velocity-stop-line-module \
    autoware-behavior-velocity-traffic-light-module \
    autoware-behavior-velocity-virtual-traffic-light-module \
    autoware-behavior-velocity-walkway-module \
    sample-vehicle-description \
    sample-vehicle-launch \
    sample-sensor-kit-description \
    sample-sensor-kit-launch \
    ros2launch \
"
