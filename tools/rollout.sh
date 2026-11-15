#!/usr/bin/env bash
# Regenerate the full recipe set for one ROS distro and Autoware ref (tag or SHA):
# mash, classify failures, compute the in-scope list, sync recipes, and with
# --build, bitbake every in-scope package. Packages it can't handle are listed
# in results/universe-<ref>/skipped-packages.json, never dropped silently.
#
# Usage: tools/rollout.sh --ros-distro <distro> --autoware-ref <tag-or-sha>
#                         [--output <dir>] [--no-mash] [--build]
#   --output   defaults to meta-autoware/generated-recipes
#   --no-mash  reuse results/universe-<ref>/build_mash from an earlier run
#   --build   long-running; start it detached
set -euo pipefail

usage() {
  echo "usage: $0 --ros-distro <distro> --autoware-ref <tag-or-sha> [--output <dir>] [--no-mash] [--build]" >&2
  exit 1
}

ROS_DISTRO=""
AUTOWARE_REF=""
OUTPUT_DIR=""
DO_BUILD=false
DO_MASH=true

while [ $# -gt 0 ]; do
  case "$1" in
    --ros-distro) ROS_DISTRO="${2:?--ros-distro needs a value}"; shift 2 ;;
    --autoware-ref) AUTOWARE_REF="${2:?--autoware-ref needs a value}"; shift 2 ;;
    --output) OUTPUT_DIR="${2:?--output needs a value}"; shift 2 ;;
    --build) DO_BUILD=true; shift ;;
    --no-mash) DO_MASH=false; shift ;;
    -h|--help) usage ;;
    *) echo "error: unknown argument '$1'" >&2; usage ;;
  esac
done

[ -n "$ROS_DISTRO" ] || usage
[ -n "$AUTOWARE_REF" ] || usage

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/meta-autoware/generated-recipes}"
RESULTS_NAME="universe-${AUTOWARE_REF}"
RESULTS_DIR="$REPO_ROOT/results/${RESULTS_NAME}"
AUTOWARE_REPO_URL="https://github.com/autowarefoundation/autoware.git"

# ls-remote only knows refs, so fall back to a shallow fetch for a commit SHA
verify_ref() {
  local ref="$1"
  if git ls-remote --exit-code "$AUTOWARE_REPO_URL" "refs/tags/$ref" >/dev/null 2>&1; then
    return 0
  fi
  local tmp rc
  tmp="$(mktemp -d)"
  if git init -q "$tmp" && git -C "$tmp" fetch -q --depth 1 "$AUTOWARE_REPO_URL" "$ref" >/dev/null 2>&1; then
    rc=0
  else
    rc=1
  fi
  rm -rf "$tmp"
  return $rc
}

if [ "$DO_MASH" = true ]; then
  if ! verify_ref "$AUTOWARE_REF"; then
    echo "error: '$AUTOWARE_REF' is not a tag or reachable commit in autowarefoundation/autoware" >&2
    exit 1
  fi
  echo "== [1/4] mash: universe manifest, Autoware ${AUTOWARE_REF} / ROS ${ROS_DISTRO} =="
  "$REPO_ROOT/tools/run-mash.sh" universe "$AUTOWARE_REF" "$ROS_DISTRO"
elif [ ! -d "$RESULTS_DIR/build_mash" ]; then
  echo "error: --no-mash needs $RESULTS_DIR/build_mash from an earlier run" >&2
  exit 1
else
  echo "== [1/4] mash: skipped, reusing $RESULTS_DIR/build_mash =="
fi

echo "== [2/4] classify: failure taxonomy + rosdep->OE mapping check =="
python3 "$REPO_ROOT/tools/classify-failures.py" "$RESULTS_NAME" --check-rosdep

echo "== [3/4] compute in-scope package list + skip manifest =="
python3 - "$RESULTS_DIR" "$REPO_ROOT/meta-autoware/PACKAGES.list" "$AUTOWARE_REF" "$ROS_DISTRO" "$REPO_ROOT/layers" \
    "$REPO_ROOT/meta-autoware/classes/autoware-fixups.bbclass" <<'PYEOF'
import json
import re
import sys
from pathlib import Path

results_dir = Path(sys.argv[1])
packages_list = Path(sys.argv[2])
autoware_ref = sys.argv[3]
ros_distro = sys.argv[4]
layers_dir = Path(sys.argv[5])
fixups_class = Path(sys.argv[6])

# ROS vendor packages named like an OE library (tier4/glog) would shadow it at our layer priority
oe_recipe_names = {
    re.sub(r"_[^_]*$", "", bb.stem)
    for sub in ("openembedded-core/meta", "meta-openembedded")
    for bb in (layers_dir / sub).rglob("*.bb")
}
if not oe_recipe_names:
    sys.exit(f"error: no OE recipes under {layers_dir}; run 'kas checkout kas/autoware.yml' first")

# CUDA/TensorRT packages whose dependency is CMake-only, invisible to the taxonomy
CUDA_NAME_RE = re.compile(r"cuda|tensorrt|nvidia|bevdet", re.IGNORECASE)

# Packages whose only CUDA dependencies the class strips without the cuda distro feature;
# they build on CPU, so they stay in scope. Read from the class so the two cannot disagree.
cuda_only_block = re.search(r"cuda_only_deps = \{(.*?)\n    \}", fixups_class.read_text(), re.DOTALL)
if not cuda_only_block:
    sys.exit(f"error: no cuda_only_deps in {fixups_class}")
cuda_optional = set(re.findall(r"^\s+'([a-z0-9-]+)':", cuda_only_block.group(1), re.MULTILINE))

# LICENSE still the upstream "TODO" placeholder; not ours to fill in
LICENSE_TODO_RE = re.compile(r'^LICENSE\s*=\s*"TODO', re.MULTILINE)

taxonomy = json.loads((results_dir / "failure-taxonomy.json").read_text())
category_by_name = {}
for cat, entries in taxonomy["categories"].items():
    for entry in entries:
        category_by_name[entry["name"]] = cat

in_scope = []
skipped = []  # [{"name":..., "category":..., "reason":...}, ...] -- never a silent drop
for bb_dir in sorted((results_dir / "build_mash").glob("*")):
    if not bb_dir.is_dir():
        continue
    pn = bb_dir.name  # build_mash dirs are already the dashed PN, matching mash's own OE-recipe naming
    ros_bpn = pn.replace("-", "_")
    bb_files = list(bb_dir.glob("*.bb"))
    license_todo = bb_files and LICENSE_TODO_RE.search(bb_files[0].read_text(errors="replace"))

    category = category_by_name.get(pn) or category_by_name.get(ros_bpn)
    if category == "cuda_or_proprietary_dep" and pn in cuda_optional:
        category = None
    if category:
        skipped.append({"name": pn, "category": category, "reason": f"mash failure taxonomy: {category}"})
        continue
    if CUDA_NAME_RE.search(pn):
        skipped.append({"name": pn, "category": "cuda_or_proprietary_dep", "reason": "CUDA, TensorRT or NVIDIA in the package name; no CUDA backend yet"})
        continue
    if pn in oe_recipe_names:
        skipped.append({"name": pn, "category": "shadows_oe_recipe", "reason": "same name as an openembedded-core/meta-openembedded recipe; that one is used instead"})
        continue
    if license_todo:
        skipped.append({"name": pn, "category": "license_todo", "reason": 'LICENSE = "TODO" placeholder, never filled in upstream'})
        continue
    in_scope.append(pn)

packages_list.write_text(
    "# Generated by tools/rollout.sh. Autoware {} / ROS {}; exclusions are in\n"
    "# results/{}/skipped-packages.json\n".format(autoware_ref, ros_distro, results_dir.name)
    + "".join(f"{p}\n" for p in in_scope)
)

skip_manifest = results_dir / "skipped-packages.json"
skip_manifest.write_text(json.dumps({
    "autoware_ref": autoware_ref,
    "ros_distro": ros_distro,
    "skipped_count": len(skipped),
    "skipped": sorted(skipped, key=lambda e: e["name"]),
}, indent=2) + "\n")

print(f"in-scope: {len(in_scope)}  skipped (see {skip_manifest.name}): {len(skipped)}")
for entry in skipped:
    print(f"  skip: {entry['name']}  [{entry['category']}]")
PYEOF

echo "== [4/4] sync in-scope recipes into ${OUTPUT_DIR} =="
"$REPO_ROOT/tools/sync-generated-recipes.sh" "$RESULTS_NAME" "$REPO_ROOT/meta-autoware/PACKAGES.list" "$OUTPUT_DIR"

# Recipes for packages this ref no longer has, or now skips; devtools ones are synced
# into the same directory from their own list
KEEP="$(cat "$REPO_ROOT/meta-autoware/PACKAGES.list" "$REPO_ROOT"/meta-autoware/PACKAGES-*.list 2>/dev/null \
  | grep -v '^#' | grep -v '^[[:space:]]*$' || true)"
for DIR in "$OUTPUT_DIR"/*/; do
  PKG="$(basename "$DIR")"
  if ! grep -qxF "$PKG" <<<"$KEEP"; then
    rm -rf "$DIR"
    echo "  removed: $PKG (not in scope for ${AUTOWARE_REF})"
  fi
done

echo "Reproduce with: tools/rollout.sh --ros-distro $ROS_DISTRO --autoware-ref $AUTOWARE_REF --output ${OUTPUT_DIR#"$REPO_ROOT"/}"

if [ "$DO_BUILD" = true ]; then
  echo "== build: every in-scope package directly =="
  REPORT="$RESULTS_DIR/rollout-report.md"
  RELEASE_LINE="$(grep -m1 'kas/releases/' "$REPO_ROOT/kas/base.yml" || echo '  (unknown -- check kas/base.yml)')"
  {
    echo "# Rollout report: Autoware ${AUTOWARE_REF} / ROS ${ROS_DISTRO}"
    echo
    echo "Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    echo "Yocto release (from kas/base.yml): ${RELEASE_LINE#*- }"
    echo
  } > "$REPORT"

  cd "$REPO_ROOT"
  # An image build only covers IMAGE_INSTALL, so target every package directly
  mapfile -t PKGS < <(grep -v '^#' "$REPO_ROOT/meta-autoware/PACKAGES.list" | grep -v '^[[:space:]]*$')
  echo "Building ${#PKGS[@]} in-scope packages directly (bitbake, not an image build)..."
  if kas shell kas/autoware.yml -c "bitbake ${PKGS[*]} -k" > "$RESULTS_DIR/build.log" 2>&1; then
    {
      echo "**Build: GREEN** -- all ${#PKGS[@]} in-scope packages built"
      echo
      echo "Package set: see meta-autoware/PACKAGES.list (this run's in-scope set)."
    } >> "$REPORT"
  else
    FAILED_COUNT="$(grep -c '^ERROR: Task.*failed' "$RESULTS_DIR/build.log" || true)"
    {
      echo "**Build: FAILED** (\`-k\` used -- ran through the full ${#PKGS[@]}-package"
      echo "set rather than stopping at the first failure; ~${FAILED_COUNT:-?} task failures logged)"
      echo
      echo "See \`results/${RESULTS_NAME}/build.log\` for the failing task(s) and"
      echo "\`results/${RESULTS_NAME}/failure-taxonomy.json\`/\`skipped-packages.json\` for"
      echo "what was excluded ahead of time."
      echo
      echo "For a \`do_configure\` failure that looks like a missing CMake package"
      echo "(\"Could not find a package configuration file provided by ...\"), run"
      echo "\`tools/find-missing-cmake-dep.sh\` against that task's log -- it checks"
      echo "whether this is a new instance of the mrt_cmake_modules-shaped class"
      echo "already handled in \`meta-autoware/classes/autoware-fixups.bbclass\`,"
      echo "or something new that needs its own line added there."
    } >> "$REPORT"
  fi
  echo
  echo "Rollout report: $REPORT"
fi
