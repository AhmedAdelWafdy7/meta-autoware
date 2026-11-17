SUMMARY = "C++ wrapper for libpng"
HOMEPAGE = "https://www.nongnu.org/pngpp/"
DESCRIPTION = "Header-only C++ interface to libpng"
SECTION = "libs"
LICENSE = "BSD-3-Clause"
LIC_FILES_CHKSUM = "file://COPYING;md5=22f1274bc9ba324d163e423c1baf0e19"

SRC_URI = "https://download.savannah.nongnu.org/releases/pngpp/png++-${PV}.tar.gz"
SRC_URI[sha256sum] = "998af216ab16ebb88543fbaa2dbb9175855e944775b66f2996fc945c8444eee1"
UPSTREAM_CHECK_URI = "https://download.savannah.nongnu.org/releases/pngpp/"
UPSTREAM_CHECK_REGEX = "png\+\+-(?P<pver>\d+(\.\d+)+)\.tar"

S = "${WORKDIR}/png++-${PV}"

# ROS packages name it by its Debian package, libpng++-dev
PROVIDES += "libpng++-dev"
DEPENDS = "libpng"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${includedir}/png++
    install -m 0644 ${S}/*.hpp ${D}${includedir}/png++/
}

# Headers only; the empty main package satisfies runtime dependencies
ALLOW_EMPTY:${PN} = "1"
RDEPENDS:${PN}-dev += "libpng-dev"

BBCLASSEXTEND = "native nativesdk"
