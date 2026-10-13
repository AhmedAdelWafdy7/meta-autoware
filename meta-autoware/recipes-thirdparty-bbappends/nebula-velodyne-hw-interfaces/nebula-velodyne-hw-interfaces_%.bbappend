# velodyne_hw_interface.cpp uses boost::format without including <boost/format.hpp>
do_configure:prepend() {
    SRC_FILE="${S}/src/velodyne_hw_interface.cpp"
    if [ -f "${SRC_FILE}" ] && ! grep -q '#include <boost/format.hpp>' "${SRC_FILE}"; then
        sed -i '1i #include <boost/format.hpp>' "${SRC_FILE}"
    fi
}
