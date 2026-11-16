# std::execution::par needs TBB, which the module does not link; with -z now it fails to dlopen
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-autoware_behavior_path_goal_planner_module-link-against-TBB.patch"
DEPENDS += "tbb"
