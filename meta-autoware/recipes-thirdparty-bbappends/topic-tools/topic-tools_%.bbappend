# meta-ros's jazzy 0001-setuptools-fix-executable.patch has no Upstream-Status, which
# wrynose's patch-status QA rejects. Drop this once meta-ros adds the header
# (https://github.com/ros/meta-ros/pull/1886).
ERROR_QA:remove = "patch-status"
WARN_QA:append = " patch-status"
