# The filter library uses CGAL and GMP without linking them; with -z now it fails to dlopen
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-autoware_pointcloud_preprocessor-link-the-filter-library-against-CGAL.patch"
