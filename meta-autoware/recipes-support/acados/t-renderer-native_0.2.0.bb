SUMMARY = "Tera template renderer used by acados to generate solver code"
HOMEPAGE = "https://github.com/acados/tera_renderer"
DESCRIPTION = "Build-time tool only: acados_template calls it to render the C code of an \
optimal control solver. Nothing from it is installed on the target."
SECTION = "devel"

# The repository has no licence file, no Cargo.toml licence field and no licence on GitHub,
# so the recipe is off until LICENSE_FLAGS_ACCEPTED has acados-tera-renderer. Drop the flag
# once upstream adds a licence.
LICENSE = "CLOSED"
LICENSE_FLAGS = "acados-tera-renderer"

SRC_URI = " \
    git://github.com/acados/tera_renderer.git;protocol=https;nobranch=1 \
    file://0001-t_renderer-add-Cargo.lock.patch \
"
# v0.2.0, the version Autoware's ansible role downloads
SRCREV = "5313666635209d868f8d7ece39cad36827c9f479"

S = "${WORKDIR}/git"

inherit cargo cargo-update-recipe-crates native

require ${BPN}-crates.inc
