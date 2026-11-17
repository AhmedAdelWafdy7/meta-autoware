SUMMARY = "Autoware sample map and rosbag for the rosbag replay demo"
DESCRIPTION = "sample-map-rosbag and sample-rosbag from Autoware's demo_artifacts, laid out as \
an Autoware map_path directory and a ros2 bag. Copyright 2020 TIER IV, Inc., with no license \
stated: demo images only, accept with LICENSE_FLAGS_ACCEPTED += \"tier4-sample-data\"."
HOMEPAGE = "https://github.com/autowarefoundation/autoware/tree/2.0.0/ansible/roles/demo_artifacts"
LICENSE = "CLOSED"
LICENSE_FLAGS = "tier4-sample-data"

SRC_URI = " \
    https://autoware-files.s3.us-west-2.amazonaws.com/maps/demos/sample-map-rosbag.zip;name=map \
    https://autoware-files.s3.us-west-2.amazonaws.com/recordings/bags/demos/sample-rosbag.zip;name=bag \
"
SRC_URI[map.sha256sum] = "07e2da0b0bf12e2324f7083c2ce5556fb8044c50cef1da6428ab9084c3903bc8"
SRC_URI[bag.sha256sum] = "5f9d36353393b3d249212153c19049822b1298db56512aa045b4f7f6fc37cf88"

S = "${WORKDIR}"

inherit allarch

MAP_DIR = "/opt/autoware/maps/sample-map-rosbag"
BAG_DIR = "/opt/autoware/bags/sample-rosbag"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${MAP_DIR} ${D}${BAG_DIR}
    install -m 0644 ${S}/sample-map-rosbag/lanelet2_map.osm ${D}${MAP_DIR}/
    install -m 0644 ${S}/sample-map-rosbag/pointcloud_map.pcd ${D}${MAP_DIR}/
    install -m 0644 ${S}/sample-map-rosbag/map_projector_info.yaml ${D}${MAP_DIR}/
    install -m 0644 ${S}/sample-rosbag/metadata.yaml ${D}${BAG_DIR}/
    install -m 0644 ${S}/sample-rosbag/sample-rosbag_0.db3 ${D}${BAG_DIR}/
}

FILES:${PN} = "${MAP_DIR} ${BAG_DIR}"
