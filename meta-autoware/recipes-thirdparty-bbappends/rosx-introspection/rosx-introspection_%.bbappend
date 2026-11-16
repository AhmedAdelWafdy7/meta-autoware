# CMakeLists downloads CPM.cmake at configure time; fetch it here and point CPM's cache at it
SRC_URI += "https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.0/CPM.cmake;downloadfilename=CPM_0.40.0.cmake;subdir=cpm-cache/cpm;name=cpm"
SRC_URI[cpm.sha256sum] = "7b354f3a5976c4626c876850c93944e52c83ec59a159ae5de5be7983f0e17a2a"
EXTRA_OECMAKE += "-DCPM_SOURCE_CACHE=${WORKDIR}/cpm-cache"
