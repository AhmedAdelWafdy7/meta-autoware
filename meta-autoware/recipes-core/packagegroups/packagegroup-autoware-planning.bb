# Tier 1 functional group, names no machine or vendor
DESCRIPTION = "Autoware planning: Rule-based planning, prediction/tracking consumers, traffic-light decision logic"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    autoware-autonomous-emergency-braking \
    autoware-behavior-path-avoidance-by-lane-change-module \
    autoware-behavior-path-bidirectional-traffic-module \
    autoware-behavior-path-direction-change-module \
    autoware-behavior-path-dynamic-obstacle-avoidance-module \
    autoware-behavior-path-external-request-lane-change-module \
    autoware-behavior-path-goal-planner-module \
    autoware-behavior-path-lane-change-module \
    autoware-behavior-path-planner \
    autoware-behavior-path-planner-common \
    autoware-behavior-path-sampling-planner-module \
    autoware-behavior-path-side-shift-module \
    autoware-behavior-path-start-planner-module \
    autoware-behavior-path-static-obstacle-avoidance-module \
    autoware-bezier-sampler \
    autoware-boundary-departure-checker \
    autoware-cluster-merger \
    autoware-collision-detector \
    autoware-costmap-generator \
    autoware-crosswalk-traffic-light-estimator \
    autoware-deprecated-boundary-departure-checker \
    autoware-detected-object-feature-remover \
    autoware-downsample-filters \
    autoware-external-velocity-limit-selector \
    autoware-freespace-planner \
    autoware-freespace-planning-algorithms \
    autoware-frenet-planner \
    autoware-goal-distance-calculator \
    autoware-lane-departure-checker \
    autoware-manual-lane-change-handler \
    autoware-mission-planner \
    autoware-mission-planner-universe \
    autoware-motion-utils \
    autoware-multi-object-tracker \
    autoware-object-merger \
    autoware-object-sorter \
    autoware-objects-of-interest-marker-interface \
    autoware-obstacle-collision-checker \
    autoware-path-distance-calculator \
    autoware-path-generator \
    autoware-path-sampler \
    autoware-path-smoother \
    autoware-perception-objects-converter \
    autoware-perception-online-evaluator \
    autoware-planning-evaluator \
    autoware-planning-factor-interface \
    autoware-planning-test-manager \
    autoware-planning-topic-converter \
    autoware-planning-validator \
    autoware-planning-validator-intersection-collision-checker \
    autoware-planning-validator-latency-checker \
    autoware-planning-validator-rear-collision-checker \
    autoware-planning-validator-test-utils \
    autoware-planning-validator-trajectory-checker \
    autoware-predicted-path-checker \
    autoware-predicted-path-postprocessor \
    autoware-remaining-distance-time-calculator \
    autoware-route-handler \
    autoware-sampler-common \
    autoware-scenario-selector \
    autoware-simple-object-merger \
    autoware-spheric-collision-detector \
    autoware-surround-obstacle-checker \
    autoware-tracking-object-merger \
    autoware-traffic-light-arbiter \
    autoware-traffic-light-category-merger \
    autoware-traffic-light-compliance-checker \
    autoware-traffic-light-occlusion-predictor \
    autoware-traffic-light-recognition-marker-publisher \
    autoware-traffic-light-selector \
    autoware-trajectory \
    autoware-trajectory-adapter \
    autoware-trajectory-concatenator \
    autoware-trajectory-follower-base \
    autoware-trajectory-follower-node \
    autoware-trajectory-ranker \
    autoware-trajectory-selector \
    autoware-trajectory-validator \
    mussp \
"
