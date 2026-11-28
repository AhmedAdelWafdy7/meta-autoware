# ROS tracetools pulls in lttng-tools, whose ptest RDEPENDS on lttng-modules, and
# lttng-modules needs CONFIG_KPROBES on kernels >= 5.7. The tegra defconfig leaves it off.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://kprobes.cfg"
