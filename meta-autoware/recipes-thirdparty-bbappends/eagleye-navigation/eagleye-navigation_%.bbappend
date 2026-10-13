# Upstream installs the library to both lib/ and lib/eagleye_navigation/ (two shlib providers)
# and exports ${S}/include, which leaks TMPDIR into -dev
do_install:append() {
    rm -f ${D}${ros_libdir}/eagleye_navigation/libeagleye_navigation.so
    sed -i -e "s#;${S}/include##" ${D}${ros_datadir}/eagleye_navigation/cmake/ament_cmake_export_include_directories-extras.cmake
}
