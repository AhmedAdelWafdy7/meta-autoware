#!/usr/bin/env python3
"""List every generated package that depends, transitively, on any of the seed
names (e.g. a dependency with no OE recipe), i.e. everything that breaks with it.

Usage:
    tools/find-reverse-closure.py <seed> [<seed> ...]
"""
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))
from _recipe_graph import build_graph  # noqa: E402


def main():
    seeds = set(sys.argv[1:])
    if not seeds:
        print("usage: find-reverse-closure.py <seed> [<seed> ...]", file=sys.stderr)
        sys.exit(1)

    recipes_dir = REPO_ROOT / "meta-autoware" / "generated-recipes"
    graph = build_graph(recipes_dir)

    memo = {}

    def depends_on_seed(pn, stack=None):
        if pn in seeds:
            return True
        if pn in memo:
            return memo[pn]
        stack = stack or set()
        if pn in stack:
            return False
        stack.add(pn)
        deps = graph.get(pn, ())
        result = any(dep in seeds or depends_on_seed(dep, stack) for dep in deps)
        memo[pn] = result
        return result

    closure = sorted(pn for pn in graph if depends_on_seed(pn))
    print(f"{len(closure)} packages transitively depend on {sorted(seeds)}:")
    for pn in closure:
        print(f"  {pn}")


if __name__ == "__main__":
    main()
