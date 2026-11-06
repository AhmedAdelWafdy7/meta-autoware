# Boost 1.87 removed the io_service API (wrynose); the replacements exist since Boost 1.66
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-io_context-build-with-Boost-1.87-and-later.patch"
