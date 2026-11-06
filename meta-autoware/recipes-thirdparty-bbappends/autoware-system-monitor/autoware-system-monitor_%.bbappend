# CMakeLists picks the arm CPU monitor from the build host's kernel name, so the result
# depends on where it was built. Machine configs choose: "raspi", "tegra", or "" for generic.
AUTOWARE_SYSTEM_MONITOR_PLATFORM ??= ""
EXTRA_OECMAKE += "-DAUTOWARE_TARGET_PLATFORM=${AUTOWARE_SYSTEM_MONITOR_PLATFORM}"
# A platform choice makes the package machine-specific; machines sharing a tune must not share it
PACKAGE_ARCH = "${@'${MACHINE_ARCH}' if d.getVar('AUTOWARE_SYSTEM_MONITOR_PLATFORM') else '${TUNE_PKGARCH}'}"

# Boost 1.87/1.88 removed io_service and made Boost.Process v2 the default, and GCC 15
# rejects the discarded exceptions() getter (wrynose); both patches build with older Boost
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " \
    file://0001-autoware_system_monitor-build-with-Boost-1.87-and-later.patch \
    file://0002-autoware_system_monitor-reset-stream-exception-masks.patch \
"

do_configure:prepend() {
    sed -i 's/CMAKE_HOST_SYSTEM_VERSION MATCHES/AUTOWARE_TARGET_PLATFORM MATCHES/' "${S}/CMakeLists.txt"

    # Missing <boost/range/iterator_range.hpp> include, and fmt v10 can't format an enum implicitly
    MSR_READER="${S}/reader/msr_reader/msr_reader.cpp"
    if [ -f "${MSR_READER}" ] && ! grep -q 'boost/range/iterator_range.hpp' "${MSR_READER}"; then
        sed -i '1i #include <boost/range/iterator_range.hpp>' "${MSR_READER}"
    fi

    VOLTAGE_MONITOR="${S}/src/voltage_monitor/voltage_monitor.cpp"
    if [ -f "${VOLTAGE_MONITOR}" ]; then
        sed -i 's/fmt::format("{}", e\.code())/fmt::format("{}", static_cast<int>(e.code()))/' "${VOLTAGE_MONITOR}"
    fi
}
