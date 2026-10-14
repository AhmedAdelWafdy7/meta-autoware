# autoware_system_designer's CMake macros write into the real install prefix at build time
# and assume a colcon workspace; redirect output to ${B} and run the manifest collector here
do_configure:prepend() {
    DEPLOY_CMAKE="${RECIPE_SYSROOT}${ros_base_prefix}/share/autoware_system_designer/cmake/autoware_system_designer_build_deploy.cmake"
    if [ -f "${DEPLOY_CMAKE}" ] && ! grep -q 'CMAKE_BINARY_DIR}/generated_deploy' "${DEPLOY_CMAKE}"; then
        sed -i 's|set(OUTPUT_ROOT_DIR "\${CMAKE_INSTALL_PREFIX}/share/\${CMAKE_PROJECT_NAME}/")|set(OUTPUT_ROOT_DIR "${CMAKE_BINARY_DIR}/generated_deploy/${CMAKE_PROJECT_NAME}/")|' "${DEPLOY_CMAKE}"
    fi

    LAUNCHER_CMAKE="${RECIPE_SYSROOT}${ros_base_prefix}/share/autoware_system_designer/cmake/autoware_system_designer_generate_launcher.cmake"
    if [ -f "${LAUNCHER_CMAKE}" ] && ! grep -q 'CMAKE_BINARY_DIR}/generated_launcher' "${LAUNCHER_CMAKE}"; then
        sed -i 's|set(LAUNCHER_FILE_DIR "\${CMAKE_INSTALL_PREFIX}/share/\${PROJECT_NAME}/launcher/")|set(LAUNCHER_FILE_DIR "${CMAKE_BINARY_DIR}/generated_launcher/${PROJECT_NAME}/launcher/")|' "${LAUNCHER_CMAKE}"
    fi

    # generate_launcher runs Python without PYTHONPATH for autoware_system_designer
    if [ -f "${LAUNCHER_CMAKE}" ] && ! grep -q 'CMAKE_COMMAND} -E env "PYTHONPATH' "${LAUNCHER_CMAKE}"; then
        AWSD_SITE_PACKAGES="${RECIPE_SYSROOT}${ros_base_prefix}/lib/python3.12/site-packages"
        sed -i "s|\${Python3_EXECUTABLE} \${SYSTEM_DESIGNER_RUNNER_SCRIPT}|\${CMAKE_COMMAND} -E env \"PYTHONPATH=${AWSD_SITE_PACKAGES}\" \${Python3_EXECUTABLE} \${SYSTEM_DESIGNER_RUNNER_SCRIPT}|" "${LAUNCHER_CMAKE}"
        sed -i "s|-- \${Python3_EXECUTABLE} \${GENERATE_LAUNCHER_PY_SCRIPT}|-- \${CMAKE_COMMAND} -E env \"PYTHONPATH=${AWSD_SITE_PACKAGES}\" \${Python3_EXECUTABLE} \${GENERATE_LAUNCHER_PY_SCRIPT}|" "${LAUNCHER_CMAKE}"
    fi

    # Collect this package's system design manifests into the staged resource dir
    RESOURCE_DIR="${RECIPE_SYSROOT}${ros_base_prefix}/share/autoware_system_designer/resource"
    if [ -d "${RESOURCE_DIR}" ] && [ ! -f "${RESOURCE_DIR}/autoware_system_design_examples.yaml" ]; then
        "${RECIPE_SYSROOT_NATIVE}/usr/bin/python3-native/python3" \
            "${S}/../autoware_system_designer/script/collect_system_design_manifests.py" \
            "${S}" \
            "${RESOURCE_DIR}" \
            "${ros_base_prefix}"
    fi
}

do_install:append() {
    GENERATED_DIR="${B}/generated_deploy/autoware_system_design_examples"
    if [ -d "$GENERATED_DIR" ]; then
        install -d "${D}${ros_base_prefix}/share/autoware_system_design_examples"
        cp -r "$GENERATED_DIR"/. "${D}${ros_base_prefix}/share/autoware_system_design_examples/"
    fi
}

# autoware_system_designer's requirements.txt
DEPENDS:append = " python3-jinja2-native python3-pyyaml-native python3-jsonschema-native"
