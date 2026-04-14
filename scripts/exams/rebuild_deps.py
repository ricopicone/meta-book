#!/usr/bin/env python3
"""
Rebuild versioned index.tex files needed by an exam/pset before generation.

The exam generator (generate_exam.py) reads from pre-built files like
common/versioned/<v>/index.tex but does not ask Make to rebuild them, so
stale versioned files get picked up when problem sources have changed.

This helper inverts common/source-dependencies.json (which maps each
versioned file to the list of problem IDs it contains) to find exactly
which versioned index.tex targets the requested problems live in, then
runs `make` on just those targets. That avoids a full-book rebuild while
still ensuring the exam sees fresh content.

Usage:
    rebuild_deps.py --config path/to/exam.yaml --base-path /path/to/book
    rebuild_deps.py --problems id1,id2,id3 --base-path /path/to/book
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Iterable

try:
    import yaml  # type: ignore
except ImportError:  # pragma: no cover
    yaml = None


def load_problem_ids_from_config(config_path: Path) -> list[str]:
    """Extract the list of problem IDs from an exam/pset YAML config."""
    if yaml is None:
        print(
            "rebuild_deps: PyYAML not installed; cannot parse config",
            file=sys.stderr,
        )
        return []
    with open(config_path) as f:
        cfg = yaml.safe_load(f) or {}
    problems = cfg.get("problems", []) or []
    ids: list[str] = []
    for p in problems:
        if isinstance(p, dict):
            pid = p.get("id") or p.get("hash")
            if pid:
                ids.append(str(pid))
        elif isinstance(p, str):
            ids.append(p)
    return ids


def parse_problem_ids(csv: str) -> list[str]:
    return [s.strip() for s in csv.split(",") if s.strip()]


def invert_deps(deps: dict) -> dict[str, str]:
    """Map each problem ID to the versioned file name that contains it."""
    id_to_version: dict[str, str] = {}
    for version, members in deps.items():
        if not isinstance(members, list):
            continue
        for pid in members:
            id_to_version[str(pid)] = str(version)
    return id_to_version


def resolve_targets(
    ids: Iterable[str], id_to_version: dict[str, str]
) -> tuple[list[str], list[str]]:
    """Return (sorted unique make targets, list of unknown IDs)."""
    targets: set[str] = set()
    unknown: list[str] = []
    for pid in ids:
        v = id_to_version.get(pid)
        if v:
            targets.add(f"common/versioned/{v}/index.tex")
        else:
            unknown.append(pid)
    return sorted(targets), unknown


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument("--config", type=Path, help="Exam/pset YAML config")
    group.add_argument(
        "--problems", help="Comma-separated problem IDs"
    )
    ap.add_argument(
        "--base-path",
        type=Path,
        required=True,
        help="Book root directory (where the Makefile lives)",
    )
    ap.add_argument(
        "--deps-file",
        default="common/source-dependencies.json",
        help="Path to source-dependencies.json, relative to --base-path",
    )
    ap.add_argument(
        "--print-only",
        action="store_true",
        help="Print the resolved make targets and exit (no make invoked)",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Pass -n to make (show what would be rebuilt, don't build)",
    )
    ap.add_argument(
        "--quiet",
        action="store_true",
        help="Suppress informational output",
    )
    args = ap.parse_args()

    base_path = args.base_path.resolve()
    deps_path = (base_path / args.deps_file).resolve()

    if not deps_path.exists():
        # Be permissive: repos without a deps file just skip the optimization.
        if not args.quiet:
            print(
                f"rebuild_deps: {deps_path} not found; skipping",
                file=sys.stderr,
            )
        return 0

    if args.config:
        ids = load_problem_ids_from_config(args.config)
    else:
        ids = parse_problem_ids(args.problems or "")

    if not ids:
        if not args.quiet:
            print("rebuild_deps: no problem IDs to resolve", file=sys.stderr)
        return 0

    with open(deps_path) as f:
        deps = json.load(f)
    id_to_version = invert_deps(deps)

    targets, unknown = resolve_targets(ids, id_to_version)

    if unknown and not args.quiet:
        print(
            "rebuild_deps: no entry in source-dependencies.json for: "
            + ", ".join(unknown),
            file=sys.stderr,
        )

    if not targets:
        if not args.quiet:
            print("rebuild_deps: no make targets resolved", file=sys.stderr)
        return 0

    if args.print_only:
        for t in targets:
            print(t)
        return 0

    cmd = ["make"]
    if args.dry_run:
        cmd.append("-n")
    cmd.extend(targets)

    if not args.quiet:
        print(
            f"rebuild_deps: running `{' '.join(cmd)}` in {base_path}",
            file=sys.stderr,
        )
    return subprocess.call(cmd, cwd=str(base_path))


if __name__ == "__main__":
    sys.exit(main())
