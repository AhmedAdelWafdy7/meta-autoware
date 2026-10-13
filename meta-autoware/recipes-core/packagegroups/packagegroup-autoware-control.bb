# Tier 1 functional group, names no machine or vendor
DESCRIPTION = "Autoware control: Vehicle command generation, MRM/hazard response"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    autoware-command-gate \
    autoware-command-mode-decider \
    autoware-command-mode-decider-plugins \
    autoware-command-mode-switcher \
    autoware-command-mode-switcher-plugins \
    autoware-command-mode-types \
    autoware-control-command-gate \
    autoware-control-evaluator \
    autoware-control-performance-analysis \
    autoware-control-validator \
    autoware-core-control \
    autoware-external-cmd-converter \
    autoware-external-cmd-selector \
    autoware-hazard-lights-selector \
    autoware-hazard-status-converter \
    autoware-joy-controller \
    autoware-mpc-lateral-controller \
    autoware-mrm-comfortable-stop-operator \
    autoware-mrm-emergency-stop-operator \
    autoware-mrm-handler \
    autoware-operation-mode-transition-manager \
    autoware-pid-longitudinal-controller \
    autoware-pure-pursuit \
    autoware-raw-vehicle-cmd-converter \
    autoware-shift-decider \
    autoware-simple-pure-pursuit \
    autoware-steer-offset-estimator \
    autoware-stop-filter \
    autoware-stop-mode-operator \
    autoware-topic-relay-controller \
    autoware-vehicle-cmd-gate \
"
