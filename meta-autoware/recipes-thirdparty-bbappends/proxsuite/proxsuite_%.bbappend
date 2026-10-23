# Autoware uses only the C++ API; the Python bindings need python3-scipy, which has no scarthgap recipe
ROS_BUILD_DEPENDS:remove = "python3-scipy"
ROS_EXPORT_DEPENDS:remove = "python3-scipy"
ROS_EXEC_DEPENDS:remove = "python3-scipy"
EXTRA_OECMAKE += "-DBUILD_PYTHON_INTERFACE=OFF"
# matio is only used by the tests, which meta-ros builds with BUILD_TESTING=OFF
ROS_BUILD_DEPENDS:remove = "matio"
