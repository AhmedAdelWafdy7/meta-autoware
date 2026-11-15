"""Dependency graph parsing shared by the find-*-closure.py tools."""
import re

DEPENDS_FIELD_RE = re.compile(
    r"^(?:ROS_BUILD_DEPENDS|ROS_EXPORT_DEPENDS|ROS_EXEC_DEPENDS|ROS_BUILDTOOL_DEPENDS)\s*=\s*\"(.*?)\"",
    re.MULTILINE | re.DOTALL,
)


def parse_deps(bb_text):
    deps = set()
    for m in DEPENDS_FIELD_RE.finditer(bb_text):
        for tok in m.group(1).replace("\\\n", " ").split():
            deps.add(tok.strip())
    return deps


def build_graph(recipes_dir):
    """recipes_dir -> {pn: set(direct deps)} for every */*.bb under it."""
    graph = {}
    for bb in sorted(recipes_dir.glob("*/*.bb")):
        pn = bb.parent.name
        graph[pn] = parse_deps(bb.read_text(errors="replace"))
    return graph
