# multigrid_ndt_omp_impl.hpp calls omp_* without #include <omp.h> (fixed upstream in 1.9.0)
do_configure:prepend() {
    NDT_OMP_IMPL="${S}/src/ndt_omp/multigrid_ndt_omp_impl.hpp"
    if [ -f "${NDT_OMP_IMPL}" ] && ! grep -q '#include <omp.h>' "${NDT_OMP_IMPL}"; then
        sed -i '/^#include <autoware\/ndt_scan_matcher\/ndt_omp\/multigrid_ndt_omp.h>$/a #include <omp.h>' "${NDT_OMP_IMPL}"
    fi
}
