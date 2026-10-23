# -Wmaybe-uninitialized false positive inside rclcpp's get_parameter_or()
CXXFLAGS:append = " -Wno-error=maybe-uninitialized"
