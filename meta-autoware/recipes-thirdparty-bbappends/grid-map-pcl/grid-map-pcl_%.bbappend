# PCL 1.13's headers use anonymous structs, and grid_map builds with -Werror and does not
# include PCL as a system directory
CXXFLAGS += "-Wno-error=pedantic"
