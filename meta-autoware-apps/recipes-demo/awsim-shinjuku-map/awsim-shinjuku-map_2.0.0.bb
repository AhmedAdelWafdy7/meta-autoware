SUMMARY = "AWSIM Shinjuku map (lanelet2 and point cloud) for Autoware"
DESCRIPTION = "Shinjuku-Map.zip from the AWSIM v2.0.0 release, laid out as an Autoware \
map_path directory. Non-commercial use only: demo images, never production."
HOMEPAGE = "https://autowarefoundation.github.io/AWSIM/Downloads/"
LICENSE = "CC-BY-NC-4.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=24261b1e6e19ba3a6dcb80b1899632fd"

SRC_URI = "https://github.com/autowarefoundation/AWSIM/releases/download/v${PV}/Shinjuku-Map.zip"
SRC_URI[sha256sum] = "f545e05d5ff3df2c7f51c57a8252003bee5777c055482e04dface02b93b579be"

S = "${WORKDIR}/Shinjuku-Map"

inherit allarch

MAP_DIR = "/opt/autoware/maps/shinjuku"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${MAP_DIR}
    install -m 0644 ${S}/map/lanelet2_map.osm ${D}${MAP_DIR}/
    install -m 0644 ${S}/map/pointcloud_map.pcd ${D}${MAP_DIR}/
    install -m 0644 ${S}/map/map_projector_info.yaml ${D}${MAP_DIR}/
}

FILES:${PN} = "${MAP_DIR}"
