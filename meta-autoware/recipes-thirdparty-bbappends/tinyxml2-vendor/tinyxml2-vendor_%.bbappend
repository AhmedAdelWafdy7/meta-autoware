# mrt_cmake_modules' FindTinyXML2 sets TinyXML2_* but this extras file reads TINYXML2_*
do_install:append() {
    EXTRAS_CMAKE="${D}${ros_base_prefix}/share/${ROS_BPN}/cmake/${ROS_BPN}-extras.cmake"
    if [ -f "${EXTRAS_CMAKE}" ] && ! grep -q 'bridge mixed-case TinyXML2 vars' "${EXTRAS_CMAKE}"; then
        sed -i '/^if(TinyXML2_FOUND AND NOT TARGET tinyxml2::tinyxml2)$/a\
  # bridge mixed-case TinyXML2 vars (e.g. from mrt_cmake_modules'"'"'s own\
  # FindTinyXML2.cmake) into the ALL-CAPS ones this file expects\
  if(NOT TINYXML2_LIBRARY AND TinyXML2_LIBRARY)\
    set(TINYXML2_LIBRARY ${TinyXML2_LIBRARY})\
  endif()\
  if(NOT TINYXML2_INCLUDE_DIR AND TinyXML2_INCLUDE_DIR)\
    set(TINYXML2_INCLUDE_DIR ${TinyXML2_INCLUDE_DIR})\
  endif()' "${EXTRAS_CMAKE}"
    fi
}
