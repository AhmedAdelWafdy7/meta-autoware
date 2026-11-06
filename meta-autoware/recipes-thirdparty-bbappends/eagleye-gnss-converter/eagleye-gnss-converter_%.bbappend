# Boost 1.89 removed the Boost.System stub library that CMake looked for (wrynose)
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-gnss_converter-do-not-look-for-Boost.System.patch"
