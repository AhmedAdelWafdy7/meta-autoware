SUMMARY = "Launcher for the Autoware rosbag replay demo"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://autoware-rosbag-replay"

S = "${WORKDIR}"

inherit allarch

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/autoware-rosbag-replay ${D}${bindir}/
}

RDEPENDS:${PN} = " \
    autoware-launch \
    autoware-sensing-launch \
    autoware-localization-launch \
    sample-sensor-kit-launch \
    sample-vehicle-launch \
    foxglove-bridge \
    ros2bag \
    rosbag2-storage-default-plugins \
    autoware-sample-rosbag \
"
