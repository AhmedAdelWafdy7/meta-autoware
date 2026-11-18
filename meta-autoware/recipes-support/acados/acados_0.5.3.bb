SUMMARY = "Fast and embedded solvers for nonlinear optimal control"
HOMEPAGE = "https://docs.acados.org"
DESCRIPTION = "acados core library with the BLASFEO linear algebra and HPIPM QP solver it \
builds in-tree. The Autoware path optimizer and trajectory modifier link it."
SECTION = "libs"

LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = " \
    file://LICENSE;md5=d0aae56f9abf0a648c46daaa9c9b0bba \
    file://external/blasfeo/LICENSE.txt;md5=32c816687e9a08fdeccc68f14604f6a8 \
    file://external/hpipm/LICENSE.txt;md5=46f588b5b724984fee85c8d829b531e5 \
"

# Only the submodules this build uses; the rest (test data, other QP solvers) are large
SRC_URI = " \
    git://github.com/acados/acados.git;protocol=https;nobranch=1;name=acados \
    git://github.com/giaf/blasfeo.git;protocol=https;nobranch=1;name=blasfeo;destsuffix=${BP}/external/blasfeo \
    git://github.com/giaf/hpipm.git;protocol=https;nobranch=1;name=hpipm;destsuffix=${BP}/external/hpipm \
"
# v0.5.3, the version Autoware's ansible role installs, and its submodule revisions
SRCREV_acados = "7e1d1152c1babd6ea04af1c9d73444fe8381057b"
SRCREV_blasfeo = "22b5a67753781879c1d2d61969ac28c87e00e3ff"
SRCREV_hpipm = "57c5dba41909787ea5460aebf7fa03f384f871be"
SRCREV_FORMAT = "acados_blasfeo_hpipm"

inherit cmake

# Upstream picks the BLASFEO kernels from the build host's CPU; pick them from the target.
# Autoware's generators use HPIPM only, so qpOASES (LGPL) and the other QP solvers stay off.
BLASFEO_TARGET ?= "GENERIC"
BLASFEO_TARGET:aarch64 ?= "ARMV8A_ARM_CORTEX_A57"
BLASFEO_TARGET:raspberrypi5 ?= "ARMV8A_ARM_CORTEX_A76"
# Its CMakeLists re-resolves CMAKE_MAKE_PROGRAM with find_program, which misses the native
# ninja under the cross toolchain's find root
EXTRA_OECMAKE = " \
    -DCMAKE_MAKE_PROGRAM=${STAGING_BINDIR_NATIVE}/ninja \
    -DBLASFEO_TARGET=${BLASFEO_TARGET} \
    -DACADOS_WITH_QPOASES=OFF \
    -DACADOS_UNIT_TESTS=OFF \
    -DACADOS_EXAMPLES=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
"

# acados installs its CMake config to <prefix>/cmake, which CMake searches on every platform
SYSROOT_DIRS += "${prefix}/cmake"
FILES:${PN}-dev += "${prefix}/cmake ${datadir}/cmake"

# Unversioned libacados.so, libblasfeo.so, libhpipm.so are what consumers link
FILES_SOLIBSDEV = ""
FILES:${PN} += "${libdir}/*.so"
INSANE_SKIP:${PN} += "dev-so"
