# Missing <boost/range/iterator_range.hpp> include, and fmt v10 can't format an enum implicitly
do_configure:prepend() {
    MSR_READER="${S}/reader/msr_reader/msr_reader.cpp"
    if [ -f "${MSR_READER}" ] && ! grep -q 'boost/range/iterator_range.hpp' "${MSR_READER}"; then
        sed -i '1i #include <boost/range/iterator_range.hpp>' "${MSR_READER}"
    fi

    VOLTAGE_MONITOR="${S}/src/voltage_monitor/voltage_monitor.cpp"
    if [ -f "${VOLTAGE_MONITOR}" ]; then
        sed -i 's/fmt::format("{}", e\.code())/fmt::format("{}", static_cast<int>(e.code()))/' "${VOLTAGE_MONITOR}"
    fi
}
