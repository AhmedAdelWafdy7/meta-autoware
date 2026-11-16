# VoxelGridNearestCentroid uses KdTreeFLANN but only links PCL common; with -z now it fails to dlopen
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-autoware_pcl_extensions-link-the-PCL-kdtree-library.patch"
