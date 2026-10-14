# Exported targets hardcode /usr/include/SDL2; resolve them against the consumer's sysroot
do_install:append() {
    for EXPORT_FILE in \
        "${D}${ros_base_prefix}/share/joy/cmake/export_joyExport.cmake" \
        "${D}${ros_base_prefix}/share/joy/cmake/export_game_controllerExport.cmake" \
    ; do
        if [ -f "$EXPORT_FILE" ]; then
            python3 -c "
import re

path = '$EXPORT_FILE'
with open(path) as f:
    content = f.read()

def sysroot_prefix_paths(match):
    prop, tokens_str = match.group(1), match.group(2)
    tokens = tokens_str.split(';')
    fixed = []
    for t in tokens:
        if t.startswith('/usr/') or t.startswith('/opt/'):
            fixed.append('\${CMAKE_SYSROOT}' + t)
        else:
            fixed.append(t)
    return prop + ' \"' + ';'.join(fixed) + '\"'

content = re.sub(
    r'(INTERFACE_INCLUDE_DIRECTORIES|INTERFACE_SYSTEM_INCLUDE_DIRECTORIES) \"([^\"]*)\"',
    sysroot_prefix_paths,
    content,
)
with open(path, 'w') as f:
    f.write(content)
"
        fi
    done
}
