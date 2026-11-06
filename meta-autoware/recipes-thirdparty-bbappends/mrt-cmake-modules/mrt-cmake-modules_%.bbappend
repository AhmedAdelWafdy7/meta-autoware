# meta-ros's jazzy add-lanelet2.patch has no Upstream-Status, which wrynose's patch-status
# QA rejects; its copies for the other ROS distros have one. Drop once meta-ros adds it.
ERROR_QA:remove = "patch-status"
WARN_QA:append = " patch-status"

# cmake_minimum_required is older than CMake 4 (wrynose) accepts; CMake 3 ignores this
EXTRA_OECMAKE += "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"

# Every package whose package.xml depends on boost gets these components looked up.
# Boost.System is header-only since 1.69 and Boost 1.89 removed its stub library, so
# asking for it fails lanelet2 and every package after it.
do_install:append() {
    yaml="${D}${ros_datadir}/mrt_cmake_modules/yaml/cmake.yaml"
    grep -q ' wave system chrono ' "$yaml" || bbfatal "Boost component list changed in $yaml; recheck this fix"
    sed -i 's/ wave system chrono / wave chrono /' "$yaml"
}
