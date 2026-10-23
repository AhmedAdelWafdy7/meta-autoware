SUMMARY = "Launcher for the Autoware planning simulator demo"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://autoware-planning-sim"

S = "${WORKDIR}"

inherit allarch

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/autoware-planning-sim ${D}${bindir}/
}

RDEPENDS:${PN} = "packagegroup-autoware-planning-simulator-demo awsim-shinjuku-map procps coreutils"
