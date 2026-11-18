SUMMARY = "acados_template, the Python interface that generates acados solver code"
HOMEPAGE = "https://docs.acados.org/python_interface"
DESCRIPTION = "Build-time tool only: the Autoware path optimizer and trajectory modifier \
run it to generate the C code of their MPC solvers."
SECTION = "devel/python"

LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=d0aae56f9abf0a648c46daaa9c9b0bba"

SRC_URI = " \
    git://github.com/acados/acados.git;protocol=https;nobranch=1 \
    file://0001-acados_template-import-scipy-and-matplotlib-only-where-they-are-used.patch \
"
SRCREV = "7e1d1152c1babd6ea04af1c9d73444fe8381057b"

inherit setuptools3 native

SETUPTOOLS_SETUP_PATH = "${S}/interfaces/acados_template"
PEP517_SOURCE_PATH = "${SETUPTOOLS_SETUP_PATH}"

DEPENDS += "python3-setuptools-scm-native"

# What code generation imports; t_renderer is found through TERA_PATH
RDEPENDS:${PN} += "python3-numpy-native python3-casadi-native python3-deprecated-native"
