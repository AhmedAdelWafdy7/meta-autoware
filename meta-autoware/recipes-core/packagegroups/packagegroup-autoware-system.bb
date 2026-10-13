# Tier 1 functional group, names no machine or vendor
DESCRIPTION = "Autoware system: Diagnostics, component/system monitoring"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    autoware-bluetooth-monitor \
    autoware-component-monitor \
    autoware-component-state-monitor \
    autoware-diagnostic-graph-aggregator \
    autoware-diagnostic-graph-test-examples \
    autoware-diagnostic-graph-utils \
    autoware-duplicated-node-checker \
    autoware-evaluation-adapter \
    autoware-glog-component \
    autoware-kinematic-evaluator \
    autoware-pipeline-latency-monitor \
    autoware-processing-time-checker \
    autoware-system-monitor \
    autoware-topic-state-monitor \
    autoware-utils-diagnostics \
"
