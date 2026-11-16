# GCC 15 rejects the narrowing in get_bitfield's mask for 8-bit storage (wrynose)
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-nebula_core_common-build-the-bitfield-mask-without-narrowing.patch"
