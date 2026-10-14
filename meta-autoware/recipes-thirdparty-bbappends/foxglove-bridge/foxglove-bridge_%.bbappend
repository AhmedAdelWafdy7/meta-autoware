# Upstream -Werror flags fire on rosidl-generated and vendored headers it includes
CXXFLAGS:append = " -Wno-error=float-equal -Wno-error=old-style-cast"
