# Boost.Uuid 1.86 no longer declares boost::hash (wrynose)
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-autoware_in_lane_mrm_planner-include-the-boost-hash-header.patch"
