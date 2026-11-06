# GCC 15 warns on unused using-declarations, and the package builds with -Werror (wrynose)
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-yabloc_common-remove-unused-using-declaration.patch"
