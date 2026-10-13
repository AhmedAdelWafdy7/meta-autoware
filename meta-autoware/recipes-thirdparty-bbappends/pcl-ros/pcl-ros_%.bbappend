# Exported target hardcodes host include/link paths; drop the redundant includes and
# resolve link libraries against the consumer's ${CMAKE_SYSROOT}
do_install:append() {
    EXPORT_FILE="${D}${ros_base_prefix}/share/pcl_ros/cmake/export_pcl_rosExport.cmake"
    if [ -f "$EXPORT_FILE" ]; then
        python3 -c "
import re

path = '$EXPORT_FILE'
with open(path) as f:
    content = f.read()

def strip_absolute_includes(match):
    tokens = match.group(1).split(';')
    kept = [t for t in tokens if not (t.startswith('/usr/') or t.startswith('/opt/'))]
    return 'INTERFACE_INCLUDE_DIRECTORIES \"' + ';'.join(kept) + '\"'

def sysroot_prefix_libs(match):
    tokens = match.group(1).split(';')
    fixed = []
    for t in tokens:
        if t.startswith('/usr/') or t.startswith('/opt/'):
            fixed.append('\${CMAKE_SYSROOT}' + t)
        else:
            fixed.append(t)
    return 'INTERFACE_LINK_LIBRARIES \"' + ';'.join(fixed) + '\"'

content = re.sub(r'INTERFACE_INCLUDE_DIRECTORIES \"([^\"]*)\"', strip_absolute_includes, content)
content = re.sub(r'INTERFACE_LINK_LIBRARIES \"([^\"]*)\"', sysroot_prefix_libs, content)
with open(path, 'w') as f:
    f.write(content)
"
    fi
}
