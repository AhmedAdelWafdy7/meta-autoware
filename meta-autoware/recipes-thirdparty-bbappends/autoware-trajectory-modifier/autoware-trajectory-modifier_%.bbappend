# Boost.Uuid 1.86 no longer declares boost::hash (wrynose)
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-autoware_trajectory_modifier-include-the-boost-hash-header.patch"
