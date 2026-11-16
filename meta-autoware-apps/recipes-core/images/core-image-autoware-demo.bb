require recipes-core/images/core-image-autoware.bb

SUMMARY = "Autoware planning simulator and rosbag replay demos"
DESCRIPTION = "${SUMMARY}. Contains a CC-BY-NC-4.0 map and TIER IV sample data with no license \
stated: not for production or commercial use."

IMAGE_INSTALL:append = " \
    packagegroup-autoware-devtools \
    autoware-planning-sim-demo \
    autoware-rosbag-replay-demo \
"
