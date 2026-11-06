# Boost.Uuid 1.86 no longer declares boost::hash (wrynose)
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-autoware_multi_object_tracker-include-the-boost-hash-header.patch"

# CMakeLists adds -mavx2 -mfma whenever the compiler accepts them, which an x86-64 compiler
# always does, whatever the target CPU. The machine's tune decides the instruction set.
do_configure:prepend:x86-64() {
    sed -i 's/add_compile_options(-mavx2 -mfma -O3)/add_compile_options(-O3)/' "${S}/CMakeLists.txt"
}
