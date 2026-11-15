#!/usr/bin/env bash
# Given a failed do_configure log, name the missing CMake package and the recipe
# that provides it. DEPENDS isn't transitive for CMake config-mode find_package().
#
# Usage: tools/find-missing-cmake-dep.sh <path-to-log.do_configure.NNNN>
set -euo pipefail

LOG="${1:?usage: $0 <path-to-log.do_configure.NNNN>}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

MISSING=$(grep -oE 'Could not find a package configuration file provided by "[A-Za-z0-9_]+"' "$LOG" \
  | head -1 | sed -E 's/.*"([A-Za-z0-9_]+)"/\1/')

if [ -z "$MISSING" ]; then
  echo "No 'Could not find a package configuration file' error found in $LOG" >&2
  exit 1
fi

DASHED="${MISSING//_/-}"
echo "Missing CMake package: $MISSING (recipe name: $DASHED)"

# log path is .../work/<arch>/<failing-recipe>/<version>/temp/log.do_configure.NNNN
FAILING_RECIPE=$(echo "$LOG" | grep -oE '/work/[^/]+/[^/]+/' | tail -1 | cut -d/ -f4)
echo "Failing recipe: ${FAILING_RECIPE:-<could not parse from log path, check manually>}"

# prefer meta-ros2-jazzy or our layer over other distros' recipes of the same name
RECIPE=$(find "$REPO_ROOT/layers/meta-ros/meta-ros2-jazzy" "$REPO_ROOT/meta-autoware" \
  "$REPO_ROOT/layers/openembedded-core" "$REPO_ROOT/layers/meta-openembedded" \
  -type f \( -iname "${DASHED}_*.bb" -o -iname "${DASHED}.bb" \) 2>/dev/null | head -1)
if [ -z "$RECIPE" ]; then
  RECIPE=$(find "$REPO_ROOT/layers" -type f \( -iname "${DASHED}_*.bb" -o -iname "${DASHED}.bb" \) 2>/dev/null | head -1)
fi

if [ -z "$RECIPE" ]; then
  echo "No existing recipe found for $DASHED -- this is a real missing_oe_recipe gap,"
  echo "not just a missing DEPENDS. Needs a new recipe, not a bbappend."
  exit 2
fi

echo "Recipe exists: $RECIPE"
echo
echo "Suggested fix -- add \"$FAILING_RECIPE\" (not $DASHED) to the appropriate"
echo "chain tuple in meta-autoware/classes/autoware-fixups.bbclass (one line,"
echo "not a new .bbappend), so it gets:"
echo "    DEPENDS += \"${DASHED}-native\""
