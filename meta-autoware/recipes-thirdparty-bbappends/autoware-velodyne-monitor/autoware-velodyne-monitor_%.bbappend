# package.xml declares crypto++, but the code never uses it: it links OpenSSL's libcrypto.
# cpprest still blocks it on Boost 1.87 and later; see the categorizer.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-autoware_velodyne_monitor-depend-on-OpenSSL-instead-of-crypto.patch"
DEPENDS:remove = "crypto++"
DEPENDS += "openssl"
RDEPENDS:${PN}:remove = "crypto++"
