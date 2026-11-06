# GCC 15 warns on unused using-declarations, and the package builds with -Werror (wrynose)
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-autoware_mission_planner_universe-remove-unused-using-declaration.patch"
