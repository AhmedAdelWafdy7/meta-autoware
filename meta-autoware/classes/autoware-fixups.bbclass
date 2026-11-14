# Fixes for upstream package.xml/CMake bugs in mash-generated recipes, applied by
# content where possible so new packages of the same shape need no new file.
# Root causes are documented in FINDINGS.md.

python() {
    import os
    import re

    pn = d.getVar('PN') or ''
    file_path = d.getVar('FILE') or ''
    depends = d.getVar('DEPENDS') or ''
    ros_build_depends = d.getVar('ROS_BUILD_DEPENDS') or ''
    # meta-ros2-jazzy also has a generated-recipes/ dir; match our layer only, by collection
    # since integrators can check the layer out under any directory name
    is_mash_generated = (
        '/generated-recipes/' in file_path
        and bb.utils.get_file_layer(file_path, d) == 'autoware-core'
    )
    # meta-ros2-jazzy recipes with the same rosidl generator tag bug
    known_thirdparty_generator_tag_recipes = {
        'udp-msgs', 'septentrio-gnss-driver', 'grid-map-msgs',
    }
    is_candidate = (
        is_mash_generated
        or pn.startswith('lanelet2')
        or pn == 'rosidl-default-runtime'
        or pn in known_thirdparty_generator_tag_recipes
    )
    if not is_candidate:
        return

    # rosidl-*-generators declared as <build_depend> instead of <buildtool_depend>
    if is_mash_generated or pn in known_thirdparty_generator_tag_recipes:
        ros_buildtool_depends = d.getVar('ROS_BUILDTOOL_DEPENDS') or ''
        for generator in set(re.findall(r'rosidl-[a-z0-9-]*-generators', ros_build_depends)):
            native = '%s-native' % generator
            if native not in ros_buildtool_depends and native not in depends:
                d.appendVar('DEPENDS', ' %s' % native)

    # Only for our recipes: adding these to meta-ros's toolchain recipes creates DEPENDS loops
    if is_mash_generated:

        # Exported CMake configs of interface packages find_package() these natives
        for native in (
            'fastrtps-cmake-module-native',
            'rosidl-default-runtime-native',
            'rosidl-generator-c-native',
            'rosidl-generator-cpp-native',
            'rosidl-typesupport-fastrtps-c-native',
            'rosidl-typesupport-fastrtps-cpp-native',
            'rosidl-typesupport-introspection-c-native',
            'rosidl-typesupport-introspection-cpp-native',
            # via autoware_cmake's export chain
            'ament-cmake-auto-native',
            # find_package(PkgConfig) without a package.xml entry
            'pkgconfig-native',
        ):
            if native not in depends:
                d.appendVar('DEPENDS', ' %s' % native)

        # pcl_ros's exported target includes pcl's headers, but consumers never declare pcl
        if ('pcl-ros' in depends or 'pcl-conversions' in depends) and 'pcl' not in depends.split():
            d.appendVar('DEPENDS', ' pcl')

        # septentrio-gnss-driver's exported target links GeographicLib
        if 'septentrio-gnss-driver' in depends.split() and 'geographiclib' not in depends.split():
            d.appendVar('DEPENDS', ' geographiclib')

        # protobuf only as exec_depend, but generated .pb.cc needs its headers
        rdepends_pn = d.getVar('RDEPENDS:%s' % pn) or ''
        if 'protobuf' in rdepends_pn.split() and 'protobuf' not in depends.split():
            d.appendVar('DEPENDS', ' protobuf')

        # generate_parameter_library as <depend> needs the native codegen too;
        # autoware-trajectory-selector doesn't declare it at all (see missing_plain_deps)
        if (
            ('generate-parameter-library' in depends.split() or pn == 'autoware-trajectory-selector')
            and 'generate-parameter-library-native' not in depends
        ):
            d.appendVar('DEPENDS', ' generate-parameter-library-native')

        # generate_parameter_library's own generated code calls the deprecated parameter_traits OK()
        if 'generate-parameter-library' in depends.split():
            d.appendVar('CXXFLAGS', ' -Wno-deprecated-declarations')

        if pn in (d.getVar('AUTOWARE_RELOCATE_CMAKE_EXPORTS') or '').split() \
                and not bb.data.inherits_class('native', d):
            d.appendVarFlag('do_install', 'postfuncs', ' autoware_relocate_cmake_exports')


    # Interface packages need the typesupport libs in their own RDEPENDS for file-rdeps QA
    consumer_deps = ' '.join([depends, d.getVar('RDEPENDS:%s' % pn) or ''])
    if pn == 'autoware-msgs':
        # meta-package: no rosidl-default-runtime reference of its own
        d.appendVar('RDEPENDS:%s' % pn, (
            ' rosidl-runtime-c rosidl-typesupport-c rosidl-typesupport-cpp'
            ' rosidl-typesupport-fastrtps-c rosidl-typesupport-fastrtps-cpp'
            ' rosidl-typesupport-introspection-c rosidl-typesupport-introspection-cpp'
            ' rcutils fastcdr python3'
        ))
    elif pn != 'rosidl-default-runtime' and 'rosidl-default-runtime' in consumer_deps:
        d.appendVar('RDEPENDS:%s' % pn, (
            ' rosidl-runtime-c rosidl-typesupport-c rosidl-typesupport-cpp'
            ' rosidl-typesupport-fastrtps-c rosidl-typesupport-fastrtps-cpp'
            ' rosidl-typesupport-introspection-c rosidl-typesupport-introspection-cpp'
            ' rcutils fastcdr libpython3 service-msgs builtin-interfaces'
        ))

    # lanelet2_core's CMake config needs mrt_cmake_modules; the list holds every package
    # that depends on lanelet2, directly or transitively
    if is_mash_generated:
        chain_list_path = os.path.join(
            d.getVar('AUTOWARE_LAYER_DIR') or '',
            'lanelet2-mrt-cmake-modules-chain.list',
        )
        try:
            with open(chain_list_path) as f:
                lanelet2_chain = {
                    line.strip() for line in f
                    if line.strip() and not line.startswith('#')
                }
        except FileNotFoundError:
            lanelet2_chain = set()
        if pn in lanelet2_chain:
            d.appendVar('DEPENDS', ' mrt-cmake-modules-native')

    # Headers used but never declared in package.xml
    missing_plain_deps = {
        'autoware-control-validator': 'angles',
        'autoware-fake-test-node': 'gtest-vendor',
        'autoware-planning-test-manager': 'gtest-vendor',
        # otherwise falls back to the host's /usr/include/SDL2
        'autoware-joy-controller': 'libsdl2',
        'autoware-perception-online-evaluator': 'lanelet2-core',
        'autoware-trajectory-selector': 'generate-parameter-library',
        'autoware-planning-validator-rear-collision-checker': 'magic-enum',
        'autoware-planning-validator-intersection-collision-checker': 'magic-enum',
        # src/test_utils.cpp is part of the main library
        'autoware-behavior-velocity-planner': 'autoware-planning-test-manager',
    }
    if pn in missing_plain_deps and missing_plain_deps[pn] not in depends.split():
        d.appendVar('DEPENDS', ' %s' % missing_plain_deps[pn])

    # Public headers include <gtest/gtest.h>, for these packages and anything built against
    # them; gtest-vendor installs the headers under src/
    if is_mash_generated:
        depends = d.getVar('DEPENDS') or ''
        gtest_headers = ('autoware-fake-test-node', 'autoware-planning-test-manager')
        if pn in gtest_headers or any(p in depends.split() for p in gtest_headers):
            if 'gtest-vendor' not in depends.split():
                d.appendVar('DEPENDS', ' gtest-vendor')
            d.appendVar('CXXFLAGS', ' -I${RECIPE_SYSROOT}${ros_base_prefix}/src/gtest_vendor/include')

    # mash wrote "branch=HEAD" (ros-mash bug); SRCREV is correct
    ros_branch_fixes = {
        'mussp': 'branch=tier4/main',
        'pointcloud-to-laserscan': 'branch=tier4/main',
    }
    if pn in ros_branch_fixes:
        d.setVar('ROS_BRANCH', ros_branch_fixes[pn])

    # range-v3 is header-only, there is no runtime package to depend on
    rdep_key = 'RDEPENDS:%s' % pn
    current = (d.getVar(rdep_key) or '').split()
    if 'range-v3' in current:
        d.setVar(rdep_key, ' '.join(v for v in current if v != 'range-v3'))

    def strip_deps(names):
        for key in ('DEPENDS', rdep_key):
            current = (d.getVar(key) or '').split()
            kept = [v for v in current if v not in names]
            if len(kept) != len(current):
                d.setVar(key, ' '.join(kept))

    # Dependencies on excluded CUDA packages, kept when a BSP sets DISTRO_FEATURES:cuda
    cuda_only_deps = {
        'autoware-planning-launch': ['autoware-diffusion-planner'],
        'autoware-perception-launch': [
            'autoware-bevfusion', 'autoware-bytetrack', 'autoware-cuda-pointcloud-preprocessor',
            'autoware-ground-segmentation-cuda',
            'autoware-image-projection-based-fusion', 'autoware-lidar-apollo-instance-segmentation',
            'autoware-lidar-centerpoint', 'autoware-lidar-transfusion', 'autoware-ptv3',
            'autoware-shape-estimation', 'autoware-simpl-prediction', 'autoware-tensorrt-bevdet',
            'autoware-tensorrt-yolox', 'autoware-traffic-light-classifier',
            'autoware-traffic-light-fine-detector',
        ],
        'autoware-sensing-launch': ['autoware-cuda-pointcloud-preprocessor'],
        'autoware-probabilistic-occupancy-grid-map': [
            'autoware-cuda-dependency-meta', 'autoware-cuda-utils',
        ],
    }
    if pn in cuda_only_deps and not bb.utils.contains('DISTRO_FEATURES', 'cuda', True, False, d):
        strip_deps(cuda_only_deps[pn])

    # Runtime-only dependencies that cannot be built here (no recipe for acados, cgal,
    # crypto++, libpng++; no Qt) and that the planning simulator does not start
    unbuildable_rdepends = {
        # path optimizer and trajectory modifier need acados
        'autoware-planning-launch': ['autoware-path-optimizer', 'autoware-trajectory-modifier'],
        'autoware-perception-launch': [
            'autoware-pointcloud-preprocessor', 'autoware-ground-segmentation',
            'autoware-compare-map-segmentation', 'autoware-euclidean-cluster',
            'autoware-detection-by-tracker', 'autoware-occupancy-grid-map-outlier-filter',
            'autoware-raindrop-cluster-filter', 'autoware-detected-object-validation',
            'autoware-elevation-map-loader',
        ],
        'autoware-probabilistic-occupancy-grid-map': ['autoware-pointcloud-preprocessor'],
        'tier4-simulator-launch': ['autoware-localization-launch', 'autoware-elevation-map-loader'],
        'autoware-launch': ['rviz2', 'autoware-localization-launch'],
        'autoware-dummy-diag-publisher': ['rqt-reconfigure', 'rqt-robot-monitor', 'rqt-runtime-monitor'],
        # pointcloud preprocessor needs cgal; the driver launch needs nebula (libpng++) and
        # the velodyne monitor (crypto++)
        'autoware-sensing-launch': ['autoware-pointcloud-preprocessor'],
        'sample-sensor-kit-launch': [
            'autoware-pointcloud-preprocessor', 'autoware-sensor-driver-launch', 'usb-cam',
        ],
    }
    if pn in unbuildable_rdepends:
        current = (d.getVar(rdep_key) or '').split()
        d.setVar(rdep_key, ' '.join(v for v in current if v not in unbuildable_rdepends[pn]))

    # Unversioned .so in the runtime package (lanelet2*, glog)
    d.appendVar('INSANE_SKIP:%s' % pn, ' dev-so')

    # Script shebang longer than 128 bytes; real fix is rewriting it in do_install.
    # Unscoped INSANE_SKIP too, do_qa_staging only reads that one.
    if pn == 'autoware-adapi-visualizers':
        d.appendVar('INSANE_SKIP:%s' % pn, ' shebang-size file-rdeps')
        d.appendVar('INSANE_SKIP', ' shebang-size file-rdeps')

    # meta-ros2-jazzy's recipe lists only action-msgs and service-msgs
    if pn == 'rosidl-default-runtime':
        d.appendVar('RDEPENDS:%s' % pn, (
            ' rosidl-runtime-c rosidl-typesupport-c rosidl-typesupport-cpp'
            ' rosidl-typesupport-fastrtps-c rosidl-typesupport-fastrtps-cpp'
            ' rosidl-typesupport-introspection-c rosidl-typesupport-introspection-cpp'
            ' rcutils fastcdr libpython3 service-msgs'
        ))
}

# Packages whose exported CMake files keep absolute paths into their own recipe sysroot,
# which is wrong for every consumer and fatal buildpaths QA on wrynose. Listed rather than
# applied to all, so the other recipes keep their task hashes.
AUTOWARE_RELOCATE_CMAKE_EXPORTS = "agnocastlib autoware-osqp-interface autoware-qp-interface sync-tooling-msgs"

# CMAKE_SYSROOT is the consumer's sysroot when OE or its SDK cross-compiles, and empty on
# target. The braces are escaped so BitBake leaves ${CMAKE_SYSROOT} for CMake.
autoware_relocate_cmake_exports() {
    files=$(grep -rlF --include='*.cmake' '${RECIPE_SYSROOT}/' ${D} || true)
    if [ -z "$files" ]; then
        bbwarn "No ${RECIPE_SYSROOT} paths in ${PN}'s CMake files; drop it from AUTOWARE_RELOCATE_CMAKE_EXPORTS"
        return
    fi
    echo "$files" | xargs sed -i "s#${RECIPE_SYSROOT}/#$\{CMAKE_SYSROOT\}/#g"
}

# Map non-SPDX license names from package.xml to SPDX ids. Runs as an event
# handler because base.bbclass checks the LICENSE format before any python().
AUTOWARE_LICENSE_MAP = "Apache 2=Apache-2.0;Apache2=Apache-2.0;CC BY-SA 4.0=CC-BY-SA-4.0;BSD3=BSD-3-Clause;BSD-3-Clause-License=BSD-3-Clause;BSD-2=BSD-2-Clause;Boost=BSL-1.0"
# plain "BSD" only where the upstream license text was checked and is BSD-3-Clause (lanelet2* too)
AUTOWARE_LICENSE_BSD3 = " \
    autoware-ndt-scan-matcher \
    eagleye-can-velocity-converter eagleye-coordinate eagleye-msgs eagleye-navigation eagleye-rt eagleye-tf \
    eigen-stl-containers geodesy geometric-shapes random-numbers \
    grid-map-cmake-helpers grid-map-core grid-map-costmap-2d grid-map-cv grid-map-msgs grid-map-ros \
    pointcloud-to-laserscan rtklib-msgs ublox-gps ublox-msgs ublox-serialization \
    velodyne-description velodyne-driver velodyne-msgs velodyne-pointcloud \
"
# plain "BSD" with no license text upstream at all; BSD-3-Clause is the ROS convention, not checked
AUTOWARE_LICENSE_BSD3_INFERRED = "autoware-image-object-locator geographic-info geographic-msgs nmea-msgs"

addhandler autoware_license_handler
autoware_license_handler[eventmask] = "bb.event.RecipePostKeyExpansion"
python autoware_license_handler() {
    import re
    d = e.data
    pn = d.getVar('PN') or ''
    file_path = d.getVar('FILE') or ''
    layer = bb.utils.get_file_layer(file_path, d)
    is_generated = layer == 'autoware-core' and '/generated-recipes/' in file_path
    if not is_generated and layer not in ('ros-common-layer', 'ros2-layer', 'ros2-jazzy-layer'):
        return
    lic = d.getVar('LICENSE') or ''
    new = lic
    pairs = (d.getVar('AUTOWARE_LICENSE_MAP') or '').split(';')
    bsd3 = ((d.getVar('AUTOWARE_LICENSE_BSD3') or '') + ' ' + (d.getVar('AUTOWARE_LICENSE_BSD3_INFERRED') or '')).split()
    if pn.startswith('lanelet2') or pn in bsd3:
        pairs.append('BSD=BSD-3-Clause')
    for pair in pairs:
        old, _, spdx = pair.partition('=')
        if old:
            new = re.sub(r'(?<![\w.-])%s(?![\w.-])' % re.escape(old), spdx, new)
    if new != lic:
        d.setVar('LICENSE', new)
}
