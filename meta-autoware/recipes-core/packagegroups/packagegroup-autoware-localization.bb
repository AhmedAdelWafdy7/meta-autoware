# Tier 1 functional group, names no machine or vendor
DESCRIPTION = "Autoware localization: Pose/odometry estimation (NDT, EKF, GNSS-based, ...)"
LICENSE = "Apache-2.0"
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

PACKAGES = "${PN}"
ALLOW_EMPTY:${PN} = "1"

RDEPENDS:${PN} += "\
    autoware-ar-tag-based-localizer \
    autoware-automatic-pose-initializer \
    autoware-core-localization \
    autoware-ekf-localizer \
    autoware-geo-pose-projector \
    autoware-gyro-odometer \
    autoware-landmark-manager \
    autoware-localization-error-monitor \
    autoware-localization-evaluator \
    autoware-localization-util \
    autoware-ndt-scan-matcher \
    autoware-pose-covariance-modifier \
    autoware-pose-estimator-arbiter \
    autoware-pose-initializer \
    autoware-pose-instability-detector \
    autoware-pose2twist \
    autoware-twist2accel \
    eagleye-can-velocity-converter \
    eagleye-coordinate \
    eagleye-fix2kml \
    eagleye-geo-pose-converter \
    eagleye-geo-pose-fusion \
    eagleye-gnss-converter \
    eagleye-navigation \
    eagleye-rt \
    eagleye-tf \
    yabloc-common \
    yabloc-image-processing \
    yabloc-monitor \
    yabloc-particle-filter \
    yabloc-pose-initializer \
"
