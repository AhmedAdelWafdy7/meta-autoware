# Tier 1 functional group, names no machine or vendor
DESCRIPTION = "Autoware common: Cross-cutting utilities and infra (autoware_utils, adapi, agnocast, ...)"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    agnocast \
    agnocast-cie-thread-configurator \
    agnocast-components \
    agnocast-e2e-test \
    agnocast-ioctl-wrapper \
    agnocast-sample-application \
    agnocast-sample-interfaces \
    agnocastlib \
    autoware-adapi-adaptors \
    autoware-adapi-specs \
    autoware-agnocast-wrapper \
    autoware-cmake \
    autoware-component-interface-tools \
    autoware-component-interface-utils \
    autoware-core-api \
    autoware-core-perception \
    autoware-default-adapi \
    autoware-default-adapi-universe \
    autoware-fake-test-node \
    autoware-geography-utils \
    autoware-global-parameter-loader \
    autoware-interpolation \
    autoware-kalman-filter \
    autoware-lint-common \
    autoware-marker-utils \
    autoware-node \
    autoware-object-recognition-utils \
    autoware-osqp-interface \
    autoware-pcl-extensions \
    autoware-point-types \
    autoware-pyplot \
    autoware-qos-utils \
    autoware-rtc-interface \
    autoware-signal-processing \
    autoware-test-node \
    autoware-test-utils \
    autoware-testing \
    autoware-time-utils \
    autoware-traffic-light-utils \
    autoware-universe-utils \
    autoware-utils \
    autoware-utils-debug \
    autoware-utils-geometry \
    autoware-utils-logging \
    autoware-utils-math \
    autoware-utils-pcl \
    autoware-utils-rclcpp \
    autoware-utils-system \
    autoware-utils-tf \
    autoware-utils-uuid \
    autoware-utils-visualization \
    glog \
    llh-converter \
    managed-transform-buffer \
    negotiated \
    negotiated-examples \
    negotiated-interfaces \
    perception-utils \
    tier4-api-utils \
"
