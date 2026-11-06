# Boost 1.87 removed ip::address::from_string() and expires_from_now() (wrynose)
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-tcp_driver-build-with-Boost-1.87-and-later.patch"
