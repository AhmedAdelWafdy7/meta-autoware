# For packages that generate acados solver code at build time (the path optimizer and the
# trajectory modifier). Their CMake runs ${ACADOS_SOURCE_DIR}/.venv/bin/python3 on a
# generator script and adds ${ACADOS_SOURCE_DIR}/include/... to the include path, the layout
# of Autoware's /opt/acados install. Build that layout from the native tools and the target
# sysroot.

inherit python3native

DEPENDS += " \
    acados \
    t-renderer-native \
    python3-acados-template-native \
    python3-casadi-native \
    python3-numpy-native \
    python3-deprecated-native \
"

ACADOS_ENV_DIR = "${WORKDIR}/acados-env"
export ACADOS_SOURCE_DIR = "${ACADOS_ENV_DIR}"
export TERA_PATH = "${STAGING_BINDIR_NATIVE}/t_renderer"
export ACADOS_PYTHON_INTERFACE_PATH = "${STAGING_LIBDIR_NATIVE}/${PYTHON_DIR}/site-packages/acados_template"

do_configure:prepend() {
    rm -rf ${ACADOS_ENV_DIR}
    mkdir -p ${ACADOS_ENV_DIR}/.venv/bin
    ln -s ${PYTHON} ${ACADOS_ENV_DIR}/.venv/bin/python3
    ln -s ${RECIPE_SYSROOT}${includedir} ${ACADOS_ENV_DIR}/include
}
