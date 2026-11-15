#!/usr/bin/env python3
"""Turn a tools/run-mash.sh run into a failure taxonomy.

Usage:
    tools/classify-failures.py <core|universe>[-TAG] [--check-rosdep]

Reads results/<arg>/mash.log and build_mash/, writes
results/<arg>/failure-taxonomy.json and prints a markdown summary.

Categories:
  unresolved_rosdep_key   not a rosdep key for any OS
  missing_oe_recipe       rosdep key with no openembedded mapping
  cuda_or_proprietary_dep CUDA/TensorRT/proprietary dependency
  monorepo_path_handling  recipe S doesn't match mash's repo path
  malformed_package_xml   package.xml mash couldn't parse
  other                   annotated individually

Most "Could not resolve external package X" warnings name a package mash
generated in the same run; those are split out rather than counted as gaps.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MODE_RE = re.compile(r"^(core|universe)(-.+)?$")

CUDA_KEYWORDS = re.compile(r"cuda|tensorrt|cudnn|cublas|nvidia|nvinfer", re.IGNORECASE)

# rosdep has no openembedded entry for these (checked in the ros:jazzy container);
# used when --check-rosdep isn't passed
VERIFIED_MISSING_OE_RECIPE = {
    "cgal",
    "crypto++",
    "libexpected-dev",
    "libpng++-dev",
}


def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def extract_discovered(mash_log_text):
    """Package names mash generated a recipe for, taken from the listing's first
    column (folder names can differ from package names)."""
    return set(re.findall(r"^([A-Za-z0-9_]+)\s+src/", mash_log_text, re.MULTILINE))


def extract_unresolved(mash_log_text):
    """Unique 'Could not resolve external package X' names, with counts."""
    names = re.findall(r"Could not resolve external package ([A-Za-z0-9_+.-]+)", mash_log_text)
    counts = {}
    for n in names:
        counts[n] = counts.get(n, 0) + 1
    return counts


def check_rosdep_live(name):
    """Look up a key in the rosdep db inside a ros:jazzy container. Returns
    'missing_oe_recipe', 'unresolved_rosdep_key', or None if it couldn't check."""
    runtime = None
    for candidate in ("docker", "podman"):
        if subprocess.run(["which", candidate], capture_output=True).returncode == 0:
            runtime = candidate
            break
    if runtime is None:
        return None

    def resolves(os_arg):
        r = subprocess.run(
            [runtime, "run", "--rm", "ros:jazzy", "rosdep", "resolve", name, "--os", os_arg],
            capture_output=True, text=True, timeout=120,
        )
        return r.returncode == 0

    try:
        known_elsewhere = resolves("ubuntu:noble")
        known_oe = resolves("openembedded:scarthgap")
    except Exception:
        return None

    if known_oe:
        return None  # actually resolves -- shouldn't have been "unresolved" at all
    return "missing_oe_recipe" if known_elsewhere else "unresolved_rosdep_key"


def check_monorepo_path_handling(build_mash_dir, mash_log_text):
    """Compare each recipe's S with mash's reported repo path for that package."""
    reported_paths = dict(re.findall(
        r"^(\S+)\s+src/.*\n\t- ROS package manifest: [^\n]+\n\t- Package repo path: (\S+)",
        mash_log_text, re.MULTILINE,
    ))
    mismatches = []
    for bb in build_mash_dir.glob("*/*.bb"):
        text = bb.read_text(errors="replace")
        m = re.search(r'^S = "\$\{WORKDIR\}/git(\S*)"', text, re.MULTILINE)
        if not m:
            continue
        s_path = m.group(1) or "/"
        pkg_name = bb.stem.rsplit("_", 1)[0]
        # .bb filenames are dashed, ROS_BPN has the real ROS name
        bpn_match = re.search(r'^ROS_BPN = "([^"]+)"', text, re.MULTILINE)
        bpn = bpn_match.group(1) if bpn_match else pkg_name
        reported = reported_paths.get(bpn)
        if reported is not None and reported != s_path:
            mismatches.append({"package": bpn, "recipe_S": s_path, "mash_reported_path": reported})
    return mismatches


def check_cuda_recipes(build_mash_dir):
    """Recipes depending on CUDA/TensorRT. These never show up as unresolved
    warnings because the CUDA package is itself generated in the same run."""
    hits = []
    for bb in sorted(build_mash_dir.glob("*/*.bb")):
        text = bb.read_text(errors="replace")
        deps_block = "\n".join(re.findall(r'^ROS_(?:BUILD|EXEC)_DEPENDS = "(.*?)"', text, re.DOTALL | re.MULTILINE))
        if CUDA_KEYWORDS.search(deps_block):
            bpn_match = re.search(r'^ROS_BPN = "([^"]+)"', text, re.MULTILINE)
            hits.append(bpn_match.group(1) if bpn_match else bb.stem)
    return hits


def check_malformed_package_xml(discovered_count, recipe_count):
    """Caveat: a package.xml too broken to be discovered at all can't be
    detected from mash's output."""
    if discovered_count != recipe_count:
        return recipe_count, f"{discovered_count - recipe_count} discovered packages got no recipe"
    return 0, None


def main():
    if len(sys.argv) < 2 or not MODE_RE.match(sys.argv[1]):
        fail(f"usage: {sys.argv[0]} <core|universe|core-TAG|universe-TAG> [--check-rosdep]")
    mode = sys.argv[1]
    check_rosdep = "--check-rosdep" in sys.argv[2:]

    results_dir = REPO_ROOT / "results" / mode
    mash_log_path = results_dir / "mash.log"
    build_mash_dir = results_dir / "build_mash"
    if not mash_log_path.exists():
        fail(f"{mash_log_path} not found -- run tools/run-mash.sh {mode} first")

    mash_log_text = mash_log_path.read_text(errors="replace")

    discovered = extract_discovered(mash_log_text)
    unresolved = extract_unresolved(mash_log_text)
    recipe_count = len(list(build_mash_dir.glob("*/*.bb"))) if build_mash_dir.exists() else 0

    self_resolved = {n: c for n, c in unresolved.items() if n in discovered}
    genuinely_external = {n: c for n, c in unresolved.items() if n not in discovered}

    categories = {
        "unresolved_rosdep_key": [],
        "missing_oe_recipe": [],
        "cuda_or_proprietary_dep": [],
        "monorepo_path_handling": [],
        "malformed_package_xml": [],
        "other": [],
    }

    for name, count in sorted(genuinely_external.items()):
        if CUDA_KEYWORDS.search(name):
            categories["cuda_or_proprietary_dep"].append({"name": name, "occurrences": count})
            continue
        verdict = None
        if check_rosdep:
            verdict = check_rosdep_live(name)
        if verdict is None and name in VERIFIED_MISSING_OE_RECIPE:
            verdict = "missing_oe_recipe"
        if verdict is None:
            categories["other"].append({
                "name": name, "occurrences": count,
                "note": "not classified -- rerun with --check-rosdep (needs docker/podman) "
                        "to resolve automatically, or annotate by hand",
            })
        else:
            categories[verdict].append({"name": name, "occurrences": count})

    monorepo_mismatches = check_monorepo_path_handling(build_mash_dir, mash_log_text)
    categories["monorepo_path_handling"] = monorepo_mismatches

    # see check_cuda_recipes
    already_flagged = {e["name"] for e in categories["cuda_or_proprietary_dep"]}
    cuda_recipe_names = [n for n in check_cuda_recipes(build_mash_dir) if n not in already_flagged]
    categories["cuda_or_proprietary_dep"].extend(
        {"name": n, "source": "recipe_content_scan"} for n in cuda_recipe_names
    )
    for entry in categories["cuda_or_proprietary_dep"]:
        entry.setdefault("source", "unresolved_warning")

    malformed_count, malformed_note = check_malformed_package_xml(len(discovered), recipe_count)

    report = {
        "mode": mode,
        "packages_discovered": len(discovered),
        "recipes_generated": recipe_count,
        "unresolved_warnings_total_occurrences": sum(unresolved.values()),
        "unresolved_warnings_unique_names": len(unresolved),
        "self_resolved_false_positives": {
            "count": len(self_resolved),
            "note": "mash reported these as unresolvable external deps, but mash itself "
                    "discovered and generated a recipe for every one of them in this same "
                    "run -- a self-resolution bug, not a real dependency gap",
            "names": sorted(self_resolved),
        },
        "categories": categories,
    }

    out_path = results_dir / "failure-taxonomy.json"
    out_path.write_text(json.dumps(report, indent=2))

    print(f"# {mode}\n")
    print(f"| packages discovered | recipes generated | unresolved warnings (unique) | self-resolved false positives | genuinely external |")
    print(f"|---|---|---|---|---|")
    print(f"| {len(discovered)} | {recipe_count} | {len(unresolved)} | {len(self_resolved)} | {len(genuinely_external)} |")
    print()
    for cat, items in categories.items():
        print(f"- **{cat}**: {len(items)}")
    if malformed_note:
        print(f"  - note: {malformed_note}")
    else:
        print(f"  - malformed_package_xml: 0 confirmed at the mash-log level (discovered == "
              f"recipes generated); not independently verified against raw package.xml count "
              f"in source tree, see script docstring")
    print(f"\nFull detail: {out_path}")


if __name__ == "__main__":
    main()
