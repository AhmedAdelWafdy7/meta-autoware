#!/usr/bin/env python3
"""Assign each package in meta-autoware/PACKAGES.list to a packagegroup by name pattern.

Heuristic, not a domain review: anything unmatched is reported as
"uncategorized" instead of being forced into a group. Rules are checked in
order, most specific first.

Usage:
    tools/categorize-packages.py [meta-autoware/PACKAGES.list]

Writes meta-autoware/package-categories.json and prints counts to stderr.
"""
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Need Qt5/X11/OpenGL, which the target image doesn't have
QT5_GAP_NAMES = {
    "autoware-bag-time-manager-rviz-plugin", "autoware-localization-rviz-plugin",
    "autoware-mission-details-overlay-rviz-plugin", "autoware-overlay-rviz-plugin",
    "autoware-perception-rviz-plugin", "autoware-planning-rviz-plugin",
    "autoware-polar-grid", "autoware-string-stamped-rviz-plugin",
    "autoware-topic-text-overlay-rviz-plugin", "autoware-traffic-light-rviz-plugin",
    "autoware-adapi-visualizers", "rviz-2d-overlay-plugins",
    "tier4-adapi-rviz-plugin", "tier4-camera-view-rviz-plugin",
    "tier4-control-mode-rviz-plugin", "tier4-datetime-rviz-plugin",
    "tier4-dummy-object-rviz-plugin", "tier4-manual-lane-change-rviz-plugin",
    "tier4-perception-rviz-plugin", "tier4-planning-factor-rviz-plugin",
    "tier4-state-rviz-plugin", "tier4-traffic-light-rviz-plugin",
    "tier4-vehicle-rviz-plugin", "autoware-traffic-light-visualization",
}

# Vendor or sensor-SKU bindings; these belong in a BSP layer, not Tier 1.
# nebula itself RDEPENDS on every vendor decoder, so it is vendor-specific too.
VENDOR_SPECIFIC_NAMES = {
    "nebula", "nebula-continental", "nebula-continental-common",
    "nebula-continental-decoders", "nebula-continental-hw-interfaces",
    "nebula-hesai", "nebula-hesai-common", "nebula-hesai-decoders",
    "nebula-hesai-hw-interfaces", "nebula-robosense", "nebula-robosense-common",
    "nebula-robosense-decoders", "nebula-robosense-hw-interfaces",
    "nebula-sample", "nebula-sample-common", "nebula-sample-decoders",
    "nebula-sample-hw-interfaces", "nebula-velodyne", "nebula-velodyne-common",
    "nebula-velodyne-decoders", "nebula-velodyne-hw-interfaces",
    "camera-description", "imu-description", "livox-description",
    "autoware-livox-tag-filter", "pandar-description", "radar-description",
    "velodyne-description", "vls-description", "pandar-msgs",
    # vendor message schemas
    "continental-msgs", "continental-srvs",
}

# Depend, directly or transitively, on something with no recipe in the layers used. Each
# entry is what `bitbake -g <pn>` reports missing, so recheck with it when a recipe is added
# (the planners were left here for a python3-scipy dependency proxsuite no longer has).
MISSING_OE_RECIPE_CHAIN_NAMES = {
    # cgal, via autoware-pointcloud-preprocessor
    "autoware-pointcloud-preprocessor", "autoware-compare-map-segmentation",
    "autoware-ground-segmentation", "autoware-lidar-marker-localizer",
    "autoware-occupancy-grid-map-outlier-filter", "tier4-localization-launch",
    # python3-scipy
    "autoware-accel-brake-map-calibrator", "autoware-smart-mpc-trajectory-follower",
    # crypto++ and cpprest, via autoware-velodyne-monitor
    "autoware-velodyne-monitor", "common-sensor-launch", "single-lidar-common-launch",
    # libpng++
    "nebula-core-decoders",
    # autoware-shape-estimation (CUDA, excluded)
    "autoware-euclidean-cluster", "autoware-detection-by-tracker",
    # rviz2, qtbase
    "autoware-core", "autoware-elevation-map-loader",
    # usb-cam
    "awsim-labs-sensor-kit-launch", "awsim-sensor-kit-launch", "single-lidar-sensor-kit-launch",
    # find_package(acados) at configure time, which bitbake -g cannot see; the trajectory
    # optimizer and modifier need the path optimizer
    "autoware-path-optimizer", "autoware-trajectory-optimizer", "autoware-trajectory-modifier",
}

# Vehicle and sensor kits for the reference vehicle and the simulators. An integrator replaces
# them with their own; the planning simulator demo installs the sample kit itself.
VEHICLE_SENSOR_KIT_NAMES = {
    "sample-vehicle-description", "sample-vehicle-launch",
    "sample-sensor-kit-description", "sample-sensor-kit-launch",
    "autoware-sample-vehicle-description", "autoware-sample-sensor-kit-description",
    "autoware-awsim-sensor-kit-description", "awsim-labs-vehicle-description",
    "awsim-labs-vehicle-launch", "awsim-labs-sensor-kit-description",
    "awsim-sensor-kit-description", "common-awsim-labs-sensor-launch",
    "carla-sensor-kit-description", "carla-sensor-kit-launch",
    # RDEPENDS on autoware-sample-sensor-kit-description
    "single-lidar-sensor-kit-description",
}

# Perception packages that build on CPU once the class strips their CUDA dependencies.
# Out of the production groups until perception comes with the ai distro feature.
PERCEPTION_NAMES = {
    "autoware-detected-object-validation", "autoware-raindrop-cluster-filter",
}

# Tests, test helpers and samples; anything a production package needs from them still
# comes in through its RDEPENDS
TEST_NAMES = {
    "agnocast-e2e-test", "agnocast-sample-application", "agnocast-sample-interfaces",
    "autoware-diagnostic-graph-test-examples", "autoware-planning-validator-test-utils",
    "autoware-fake-test-node", "autoware-test-node", "autoware-test-utils", "autoware-testing",
    "autoware-planning-test-manager",
    # the agnocast metapackage, which RDEPENDS on its samples; its libraries match the
    # planning rule one by one
    "agnocast",
}

# Dev-only groups, checked before the Tier 1 rules
SIMULATION_NAMES = {
    "autoware-simple-planning-simulator",
    "autoware-dummy-perception-publisher",
    "autoware-dummy-traffic-light-publisher",
    "autoware-dummy-diag-publisher",
    "autoware-dummy-infrastructure",
    "autoware-scenario-simulator-v2-adapter",
    "autoware-vehicle-door-simulator",
    "tier4-simulator-launch",
    "autoware-fault-injection",
    "autoware-carla-interface",
    "tier4-system-launch",
    "tier4-autoware-api-launch",
    # design-time tooling
    "autoware-system-designer",
    "autoware-system-design-examples",
    "autoware-universe-designs",
    "autoware-sample-designs",
}
PLANNING_SIMULATOR_DEMO_NAMES = {
    "tier4-planning-launch",
    "tier4-control-launch",
    # starts the whole stack, simulators included
    "autoware-launch",
    # perception, with its CUDA dependencies stripped; the demo starts them
    "tier4-perception-launch",
    "autoware-probabilistic-occupancy-grid-map",
}

# (category, [substrings]), first match wins. Plain substring match on purpose:
# "control" must also match "-controller", "diagnostic" must match "-diagnostics".
RULES = [
    ("msgs", ["-msgs", "-msg", "component-interface-specs", "adapi-v1-msgs", "adapi-version-msgs"]),
    ("planning", [
        "planning", "planner", "trajectory", "behavior-path", "behavior-velocity",
        "motion-velocity", "motion-utils", "freespace", "mission-planner",
        "route-handler", "scenario-selector", "costmap-generator", "obstacle-",
        "goal-distance", "goal-planner", "path-", "frenet-planner", "bezier-sampler",
        "sampler-common", "boundary-departure", "surround-obstacle", "collision-detector",
        "collision-checker", "lane-change", "lane-departure", "remaining-distance",
        "spheric-collision",
        # tracking, fusion and traffic-light decision logic (CPU only); no non-CUDA
        # perception group exists, so they live here
        "multi-object-tracker", "object-merger", "object-sorter",
        "detected-object-validation", "detected-object-feature-remover",
        "detection-by-tracker", "tracking-object-merger", "simple-object-merger",
        "cluster-merger", "perception-objects-converter", "perception-online-evaluator",
        "traffic-light-arbiter", "traffic-light-category-merger",
        "traffic-light-compliance-checker", "traffic-light-occlusion-predictor",
        "traffic-light-recognition-marker-publisher", "traffic-light-selector",
        "crosswalk-traffic-light-estimator", "objects-of-interest-marker",
        "autonomous-emergency-braking", "predicted-path-checker", "predicted-path-postprocessor",
        # data association library used by multi_object_tracker
        "mussp", "downsample-filters", "external-velocity-limit-selector",
        "velocity-smoother",
    ]),
    ("control", [
        "control", "pure-pursuit", "mpc-lateral", "vehicle-cmd-gate",
        "raw-vehicle-cmd", "external-cmd", "command-mode", "command-gate",
        "operation-mode-transition", "stop-filter", "shift-decider",
        "trajectory-follower", "smart-mpc",
        # MRM and hazard handlers issue vehicle commands
        "hazard-lights-selector", "hazard-status-converter", "mrm-comfortable-stop",
        "mrm-emergency-stop", "mrm-handler", "stop-mode-operator", "steer-offset-estimator",
    ]),
    ("localization", [
        "localization", "localiz", "ndt-scan-matcher", "ekf-localizer",
        "gyro-odometer", "pose-initializer", "pose-estimator", "pose-instability",
        "pose-covariance", "pose2twist", "ar-tag-based-localizer", "landmark-manager",
        "yabloc", "lidar-marker-localizer", "eagleye", "geo-pose", "twist2accel",
    ]),
    ("map", ["-map", "map-", "lanelet2", "elevation-map"]),
    ("sensing", [
        "sensing", "sensor-kit", "camera", "lidar", "radar", "-imu-", "imu-corrector",
        "pointcloud", "point-cloud", "nebula", "pandar", "velodyne", "livox",
        "image-", "ground-segmentation", "ground-filter", "crop-box-filter",
        "euclidean-cluster", "occupancy-grid-map", "gnss-poser", "compare-map-segmentation",
        "raindrop-cluster", "polar-grid",
        # transport-level drivers and sensor kit descriptions
        "boost-io-context", "boost-serial-driver", "boost-tcp-driver", "boost-udp-driver",
        "ros2-socketcan", "ros2agnocast", "imu-description", "vls-description",
        "common-sensor-launch", "common-awsim-labs-sensor-launch",
        "sample-sensor-kit", "carla-sensor-kit", "single-lidar-sensor-kit",
        "awsim-sensor-kit", "awsim-labs-sensor-kit", "camera-description",
        "radar-description", "velodyne-description", "pandar-description",
        "continental-srvs", "continental-msgs",
    ]),
    ("vehicle", [
        "vehicle-info", "vehicle-description", "vehicle-velocity", "vehicle-launch",
        "sample-vehicle", "carla-vehicle", "learning-based-vehicle-model",
        "autoware-core-vehicle",
    ]),
    ("system", [
        "system-monitor", "system-msgs", "diagnostic", "component-state-monitor",
        "component-monitor", "processing-time-checker", "duplicated-node-checker",
        "glog-component", "bluetooth-monitor", "velodyne-monitor", "pipeline-latency",
        "topic-state-monitor", "topic-relay-controller", "evaluation-adapter",
        "kinematic-evaluator",
    ]),
    ("common", [
        "-utils", "utils-", "interpolation", "kalman-filter", "signal-processing",
        "-cmake", "qos-utils", "time-utils", "universe-utils", "grid-map-utils",
        "marker-utils", "interface-utils", "interface-tools", "pyplot",
        # middleware
        "agnocast", "negotiated",
        # solver interfaces
        "osqp-interface", "qp-interface", "pcl-extensions", "point-types",
        # external API
        "adapi-adaptors", "adapi-specs", "default-adapi", "objects-of-interest-marker-interface",
        "rtc-interface", "global-parameter-loader", "glog", "lint-common",
        "testing", "fake-test-node", "test-node", "node",
        "autoware-core", "autoware-core-api", "autoware-launch",
        "llh-converter", "managed-transform-buffer",
    ]),
]


def categorize(pn):
    if pn in VENDOR_SPECIFIC_NAMES or pn in VEHICLE_SENSOR_KIT_NAMES:
        return "tier2-vendor-example"
    if pn in TEST_NAMES:
        return "test"
    if pn in PERCEPTION_NAMES:
        return "perception"
    if pn in QT5_GAP_NAMES:
        return "excluded-qt5-gap"
    if pn in MISSING_OE_RECIPE_CHAIN_NAMES:
        return "excluded-missing-oe-recipe"
    if pn in SIMULATION_NAMES:
        return "simulation"
    if pn in PLANNING_SIMULATOR_DEMO_NAMES:
        return "planning-simulator-demo"
    for category, patterns in RULES:
        for pat in patterns:
            if pat in pn:
                return category
    return "uncategorized"


def main():
    packages_list = Path(sys.argv[1]) if len(sys.argv) > 1 else REPO_ROOT / "meta-autoware" / "PACKAGES.list"
    if not packages_list.is_file():
        print(f"FAIL: {packages_list} not found", file=sys.stderr)
        sys.exit(1)

    names = [
        line.strip() for line in packages_list.read_text().splitlines()
        if line.strip() and not line.startswith("#")
    ]

    result = {pn: categorize(pn) for pn in names}

    out_path = REPO_ROOT / "meta-autoware" / "package-categories.json"
    out_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")

    by_cat = {}
    for pn, cat in result.items():
        by_cat.setdefault(cat, []).append(pn)

    print(f"{len(names)} packages categorized, written to {out_path}\n", file=sys.stderr)
    for cat in sorted(by_cat):
        print(f"  {cat}: {len(by_cat[cat])}", file=sys.stderr)

    if "uncategorized" in by_cat:
        print(f"\nUncategorized ({len(by_cat['uncategorized'])}), needs manual review:", file=sys.stderr)
        for pn in sorted(by_cat["uncategorized"]):
            print(f"  {pn}", file=sys.stderr)


if __name__ == "__main__":
    main()
