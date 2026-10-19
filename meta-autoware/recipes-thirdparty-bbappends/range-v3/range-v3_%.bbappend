# Header-only: skip tests/examples/docs, and RANGES_NATIVE adds -march=native (the build host's CPU)
EXTRA_OECMAKE += "-DRANGES_NATIVE=OFF -DRANGE_V3_TESTS=OFF -DRANGE_V3_EXAMPLES=OFF -DRANGE_V3_DOCS=OFF"
