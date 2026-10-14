# Headers are installed under ${ros_base_prefix}/src, which isn't staged into sysroots by default
SYSROOT_DIRS:append = " ${ros_base_prefix}/src"
