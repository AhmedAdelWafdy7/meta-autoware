# Header-only, so no main package is produced, but yabloc-common RDEPENDS on sophus
ALLOW_EMPTY:${PN} = "1"
# Tests and examples are not installed and OOM-kill cc1plus on a 16 GB host
EXTRA_OECMAKE += "-DBUILD_SOPHUS_TESTS=OFF -DBUILD_SOPHUS_EXAMPLES=OFF"
