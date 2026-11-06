# yabloc-pose-initializer includes opencv2/dnn.hpp. meta-ros enabled dnn for every distro up to
# scarthgap; from wrynose it only does so for ROS 1. Where meta-ros still adds it, the repeated
# "dnn" builds the same opencv, though the changed PACKAGECONFIG text means one rebuild.
PACKAGECONFIG:append:class-target = " dnn"
