# mrt_cmake_modules' FindBoostPython defaults to Python 2.7 unless the caller sets
# PYTHON_VERSION; patch this recipe's staged copy (patching mrt-cmake-modules didn't stick)
do_configure:prepend() {
    MODULE_FILE="${RECIPE_SYSROOT_NATIVE}${ros_base_prefix}/share/mrt_cmake_modules/cmake/Modules/FindBoostPython.cmake"
    if [ -f "${MODULE_FILE}" ]; then
        sed -i 's/set(_python_version 2\.7)/set(_python_version 3)/' "${MODULE_FILE}"
    fi
}

# -Wmaybe-uninitialized false positive inside <boost/python/extract.hpp>
CXXFLAGS:append = " -Wno-error=maybe-uninitialized"
