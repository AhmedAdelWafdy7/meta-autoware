# Autoware includes <tl_expected/expected.hpp> (ROS layout); meta-ros2 installs <tl/expected.hpp>
do_install:append() {
    if [ -f "${D}${includedir}/tl/expected.hpp" ] && [ ! -e "${D}${includedir}/tl_expected/expected.hpp" ]; then
        install -d "${D}${includedir}/tl_expected"
        install -m 0644 "${D}${includedir}/tl/expected.hpp" "${D}${includedir}/tl_expected/expected.hpp"
    fi
}
