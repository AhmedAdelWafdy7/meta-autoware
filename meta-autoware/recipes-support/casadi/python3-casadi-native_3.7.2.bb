SUMMARY = "CasADi symbolic framework for numeric optimization, Python bindings"
HOMEPAGE = "https://web.casadi.org"
DESCRIPTION = "Build-time tool only: acados_template uses CasADi to build the symbolic \
model of an optimal control problem and generate its C code. Built without solver \
plugins, which code generation does not need."
SECTION = "devel/python"

LICENSE = "LGPL-3.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=e6a600fd5e1d9cbde2d983680233ad02"

SRC_URI = "git://github.com/casadi/casadi.git;protocol=https;nobranch=1"
# 3.7.2, the version Autoware's ansible role installs
SRCREV = "f959d3175a444d763e4eda4aece48f4c5f4a6f90"

S = "${WORKDIR}/git"

inherit cmake python3native python3-dir native

DEPENDS += "swig-native python3-native"

# Python paths passed in: upstream finds them with FindPythonInterp and distutils
EXTRA_OECMAKE = " \
    -DWITH_PYTHON=ON -DWITH_PYTHON3=ON \
    -DPYTHON_EXECUTABLE=${PYTHON} \
    -DPYTHON_INCLUDE_DIR=${STAGING_INCDIR}/${PYTHON_DIR} \
    -DPYTHON_PREFIX=${PYTHON_SITEPACKAGES_DIR} \
    -DWITH_SUNDIALS=OFF -DWITH_BUILD_SUNDIALS=OFF \
    -DWITH_CSPARSE=OFF -DWITH_BUILD_CSPARSE=OFF \
    -DWITH_TINYXML=OFF -DWITH_BUILD_TINYXML=OFF \
    -DWITH_FMI2=OFF -DWITH_FMI3=OFF \
    -DWITH_EXAMPLES=OFF \
    -DCASADI_PYTHON_PIP_METADATA_INSTALL=ON \
"
