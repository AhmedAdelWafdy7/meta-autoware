# Upstream installs the library to both lib/ and lib/llh_converter/ (two shlib providers)
# and exports ${S}/include, which leaks TMPDIR into -dev
do_install:append() {
    rm -f ${D}${ros_libdir}/llh_converter/libllh_converter.so
    sed -i -e "s#;${S}/include##" ${D}${ros_datadir}/llh_converter/cmake/ament_cmake_export_include_directories-extras.cmake
}
