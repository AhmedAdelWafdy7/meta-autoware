# CMakeLists discarded the toolchain flags: no optimisation, no target CPU, no hardening
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-CMakeLists.txt-keep-the-compiler-flags-passed-in.patch"
