# Exported config links GeographicLib but never find_package()s it
do_install:append() {
    CONFIG_FILE="${D}${ros_base_prefix}/share/septentrio_gnss_driver/cmake/septentrio_gnss_driverConfig.cmake"
    if [ -f "$CONFIG_FILE" ] && ! grep -q 'find_package(GeographicLib' "$CONFIG_FILE"; then
        sed -i 's/^# include all config extra files$/find_package(GeographicLib REQUIRED)\n\n# include all config extra files/' "$CONFIG_FILE"
    fi
}
