#!/usr/bin/env python3
"""Compare the ROS packages in an upstream Autoware image with the layer's images.

Every package in the upstream list gets one status. A package that is not in any of the given
image manifests gets a reason, from the layer's own records:

    results/universe-<ref>/skipped-packages.json   packages the generator run left out
    meta-autoware/package-categories.json          group of every generated recipe
    meta-autoware/PACKAGES.list                    generated recipes, with the skipped ones
                                                   the Autoware version's package set
    layers/meta-ros                                recipes meta-ros provides
    tools/parity-notes.json                        reasons for the rest, written by hand

The run fails if a package is left without a reason.

Usage:
    tools/compare-upstream.py --upstream results/upstream/universe-jazzy-2.0.0.json \
        [--autoware-ref 1.9.0] --manifest <name>=<image.manifest> [--manifest ...] \
        --output results/parity/universe-jazzy-2.0.0
"""
import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# status -> what it means; the closed list a package's status must come from
REASONS = {
    "in-image": "installed in the first image given",
    "in-other-image": "installed in another of the images given, not the first",
    "not-in-autoware-ref": "not in the Autoware version the layer is generated from",
    "cuda": "left out here as a CUDA or TensorRT package",
    "missing-oe-recipe": "a dependency has no recipe in any layer used",
    "qt": "needs Qt or RViz, not shipped",
    "build-tool": "build tool; a -native recipe in Yocto, not installed on the target",
    "simulation": "simulator or design tool, in the dev image only",
    "vendor-example": "vendor or vehicle-specific example, not in a generic image",
    "demo": "only in the planning simulator demo",
    "shadows-oe-recipe": "an OE recipe of the same name is used instead",
    "license-todo": "upstream licence is a TODO placeholder",
    "generator-failure": "ros-mash could not generate a recipe",
    "meta-ros-not-installed": "meta-ros has a recipe; no image here installs it",
    "not-installed": "generated, but not in any image given",
    "noted": "reason in tools/parity-notes.json",
}

CATEGORY_REASON = {
    "excluded-missing-oe-recipe": "missing-oe-recipe",
    "excluded-qt5-gap": "qt",
    "simulation": "simulation",
    "tier2-vendor-example": "vendor-example",
    "planning-simulator-demo": "demo",
}

SKIP_REASON = {
    "cuda_or_proprietary_dep": "cuda",
    "shadows_oe_recipe": "shadows-oe-recipe",
    "license_todo": "license-todo",
}


# Upstream builds in place with colcon, so its image carries the build tools
BUILD_TOOL_RE = re.compile(
    r"^(ament_(cmake|lint|cppcheck|cpplint|flake8|pep257|uncrustify|xmllint|package)|rosidl_)"
    r"|_cmake_module$|_cmake_modules$|^uncrustify_vendor$|^generate_parameter_library_py$")
QT_RE = re.compile(r"rviz|rqt|(^|_)qt(_|$)|^tango_icons_vendor$")


def oe_name(ros_name):
    return ros_name.replace("_", "-").lower()


def read_list(path):
    return {line.strip() for line in path.read_text().splitlines()
            if line.strip() and not line.startswith("#")}


def read_manifest(path):
    return {line.split()[0] for line in path.read_text().splitlines() if line.strip()}


def meta_ros_recipes(layers_dir):
    names = set()
    for bb in (layers_dir / "meta-ros").rglob("*.bb"):
        names.add(re.sub(r"_[^_]*$", "", bb.stem))
    return names


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--upstream", required=True, type=Path)
    parser.add_argument("--autoware-ref", help="defaults to the one meta-autoware/PACKAGES.list was generated from")
    parser.add_argument("--manifest", action="append", required=True,
                        help="<name>=<path>; the first is the image the table is about")
    parser.add_argument("--output", required=True, type=Path, help="path without extension")
    parser.add_argument("--layers", type=Path, default=REPO_ROOT / "layers")
    args = parser.parse_args()

    if not args.autoware_ref:
        header = (REPO_ROOT / "meta-autoware" / "PACKAGES.list").read_text().splitlines()[0]
        m = re.search(r"Autoware (\S+) /", header)
        if not m:
            sys.exit("error: no Autoware version in the PACKAGES.list header; pass --autoware-ref")
        args.autoware_ref = m.group(1)
    upstream = json.loads(args.upstream.read_text())
    images = []
    for item in args.manifest:
        name, _, path = item.partition("=")
        images.append((name, read_manifest(Path(path))))

    skipped = {e["name"]: e["category"] for e in json.loads(
        (REPO_ROOT / "results" / f"universe-{args.autoware_ref}" / "skipped-packages.json")
        .read_text())["skipped"]}
    categories = json.loads((REPO_ROOT / "meta-autoware" / "package-categories.json").read_text())
    generated = read_list(REPO_ROOT / "meta-autoware" / "PACKAGES.list") \
        | read_list(REPO_ROOT / "meta-autoware" / "PACKAGES-devtools.list")
    autoware_set = generated | set(skipped)
    meta_ros = meta_ros_recipes(args.layers)
    if not meta_ros:
        sys.exit(f"error: no meta-ros recipes under {args.layers}; run 'kas checkout kas/autoware.yml'")
    notes_path = REPO_ROOT / "tools" / "parity-notes.json"
    notes = json.loads(notes_path.read_text()) if notes_path.exists() else {}

    rows = []
    for ros_name, prefix in upstream["packages"].items():
        pn = oe_name(ros_name)
        detail = ""
        if pn in images[0][1]:
            status = "in-image"
        elif any(pn in pkgs for _, pkgs in images[1:]):
            status = "in-other-image"
            detail = ", ".join(n for n, pkgs in images[1:] if pn in pkgs)
        elif pn in skipped:
            cat = skipped[pn]
            status = SKIP_REASON.get(cat, "generator-failure")
            if status == "generator-failure":
                detail = cat
        elif pn in categories and categories[pn] in CATEGORY_REASON:
            status = CATEGORY_REASON[categories[pn]]
        elif ros_name in notes:
            status = "noted"
            detail = notes[ros_name]
        elif QT_RE.search(ros_name):
            status = "qt"
        elif BUILD_TOOL_RE.search(ros_name):
            status = "build-tool"
        elif pn in generated:
            status = "not-installed"
            detail = categories.get(pn, "")
        elif prefix.startswith("/opt/autoware") and pn not in autoware_set:
            status = "not-in-autoware-ref"
        elif pn in meta_ros:
            status = "meta-ros-not-installed"
        else:
            status = None
        rows.append({"package": ros_name, "prefix": prefix, "status": status, "detail": detail})

    unexplained = [r["package"] for r in rows if r["status"] is None]
    upstream_pns = {oe_name(n) for n in upstream["packages"]}
    extra = sorted(p for p in images[0][1] & autoware_set if p not in upstream_pns)

    counts = Counter(r["status"] for r in rows if r["status"])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    Path(f"{args.output}.json").write_text(json.dumps({
        "upstream": {k: upstream[k] for k in ("image", "index_digest", "arm64_manifest_digest")},
        "autoware_ref": args.autoware_ref,
        "images": [n for n, _ in images],
        "counts": dict(counts),
        "packages": rows,
        "only_here": extra,
        "unexplained": unexplained,
    }, indent=2) + "\n")

    first = images[0][0]
    lines = [
        f"# {upstream['image'].rsplit(':', 1)[1]} against {first}",
        "",
        f"Generated by `tools/compare-upstream.py`. Upstream: `{upstream['image']}` "
        f"(`{upstream['index_digest']}`), {len(rows)} packages. Layer: Autoware "
        f"{args.autoware_ref}; images: {', '.join(f'`{n}`' for n, _ in images)}.",
        "",
        "| Status | Packages | Meaning |",
        "|---|---|---|",
    ]
    for status, meaning in REASONS.items():
        if counts.get(status):
            lines.append(f"| `{status}` | {counts[status]} | {meaning} |")
    if unexplained:
        lines.append(f"| **unexplained** | {len(unexplained)} | needs a reason |")
    lines += ["", f"Autoware packages in `{first}` but not upstream: {len(extra)}"
              + (" (" + ", ".join(f"`{p}`" for p in extra) + ")" if extra else "") + ".",
              "", "| Package | Status | Detail |", "|---|---|---|"]
    for r in rows:
        if r["status"] != "in-image":
            lines.append(f"| `{r['package']}` | `{r['status'] or 'UNEXPLAINED'}` | {r['detail']} |")
    Path(f"{args.output}.md").write_text("\n".join(lines) + "\n")

    print(", ".join(f"{k} {v}" for k, v in counts.most_common()), file=sys.stderr)
    if unexplained:
        print(f"error: {len(unexplained)} packages without a reason: {' '.join(unexplained)}",
              file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
