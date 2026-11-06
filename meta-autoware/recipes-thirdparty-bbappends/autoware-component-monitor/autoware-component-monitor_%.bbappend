# Boost 1.88 made Boost.Process v2 the default (wrynose); the patch also builds with older Boost
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-autoware_component_monitor-build-with-Boost-1.88-and-later.patch"
