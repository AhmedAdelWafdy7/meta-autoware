SUMMARY = "Computational Geometry Algorithms Library"
HOMEPAGE = "https://www.cgal.org"
DESCRIPTION = "Header-only C++ library of geometric algorithms and data structures"
SECTION = "libs"

# Each header names its own license: GPL-3.0-or-later or LGPL-3.0-or-later for CGAL itself,
# a few Boost (BSL), GPL-2.0-or-later and MIT-like (RFL) files, CC0 for the rest.
LICENSE = "GPL-3.0-or-later & GPL-3.0-only & GPL-2.0-or-later & LGPL-3.0-or-later & BSL-1.0 & MIT & CC0-1.0 & CGAL-RFL"
LIC_FILES_CHKSUM = " \
    file://LICENSE;md5=73cc2994365c56a52e864d90afb14e52 \
    file://LICENSE.GPL;md5=b61c59d0c373486d984e818f8447d96b \
    file://LICENSE.LGPL;md5=d557bfd1ad1cf093159268721af5c3c3 \
    file://LICENSE.BSL;md5=e4224ccaecb14d942c71d31bef20d78c \
    file://LICENSE.RFL;md5=5a4018dfc7bf4bd79ed528ca1df44069 \
"
NO_GENERIC_LICENSE[CGAL-RFL] = "LICENSE.RFL"

SRC_URI = "https://github.com/CGAL/cgal/releases/download/v${PV}/CGAL-${PV}-library.tar.xz"
SRC_URI[sha256sum] = "8e7ce1e30e8ffcb3e69d153c3a561bb1f38bbb4becd8e6544cbaa0fb2889af62"
UPSTREAM_CHECK_URI = "https://github.com/CGAL/cgal/releases"
UPSTREAM_CHECK_REGEX = "releases/tag/v(?P<pver>\d+(\.\d+)+)"

S = "${WORKDIR}/CGAL-${PV}"

inherit cmake

# CGALConfig.cmake looks these up when a package finds CGAL
DEPENDS = "boost gmp mpfr"

do_install:append() {
    # helper scripts for generating CMakeLists.txt, not needed to build against CGAL
    rm -rf ${D}${bindir}
}

# Headers and CMake config only; the empty main package satisfies runtime dependencies on cgal
ALLOW_EMPTY:${PN} = "1"
RDEPENDS:${PN}-dev += "boost-dev gmp-dev mpfr-dev"

BBCLASSEXTEND = "native nativesdk"
