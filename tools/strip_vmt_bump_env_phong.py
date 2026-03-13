#!/usr/bin/env python3
"""
Recursively strip selected material keys from VMT files.

Removes:
  - bumpmap
  - any key containing "envmap"
  - any key containing "phong"

Examples:
  python strip_vmt_bump_env_phong.py "C:\\...\\materials\\models\\riggs9162\\rp_black_mesa_facility" --dry-run
  python strip_vmt_bump_env_phong.py "C:\\...\\rp_black_mesa_facility" --backup-ext .bak
"""

from __future__ import annotations

import argparse
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass
class FileResult:
    path: Path
    changed: bool
    removed_lines: int
    removed_keys: list[str]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Scan a directory recursively and remove VMT fields for bumpmap, "
            "envmap-related keys, and phong-related keys."
        )
    )
    parser.add_argument(
        "input_dir",
        type=Path,
        help="Root directory to scan recursively for .vmt files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report changes without writing files",
    )
    parser.add_argument(
        "--backup-ext",
        default="",
        help="Optional backup extension (example: .bak) written before each changed file",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Only print the final summary",
    )
    return parser.parse_args()


def decode_text(data: bytes) -> tuple[str, str]:
    try:
        return data.decode("utf-8"), "utf-8"
    except UnicodeDecodeError:
        return data.decode("latin-1"), "latin-1"


def extract_key(line: str) -> str | None:
    stripped = line.lstrip()
    if not stripped:
        return None
    if stripped.startswith("//"):
        return None
    if stripped[0] in "{}":
        return None

    if stripped.startswith('"'):
        end = stripped.find('"', 1)
        if end == -1:
            return None
        return stripped[1:end]

    token = stripped.split(None, 1)[0]
    if token.startswith("//"):
        return None
    return token


def normalize_key(key: str) -> str:
    normalized = key.strip().strip('"').lower()
    while normalized.startswith("$") or normalized.startswith("%"):
        normalized = normalized[1:]
    return normalized


def should_remove_key(key: str) -> bool:
    normalized = normalize_key(key)
    if normalized == "bumpmap":
        return True
    if "envmap" in normalized:
        return True
    if "phong" in normalized:
        return True
    return False


def process_vmt_text(text: str) -> tuple[str, int, list[str]]:
    removed_lines = 0
    removed_keys: list[str] = []
    output_lines: list[str] = []

    for line in text.splitlines(keepends=True):
        line_no_nl = line.rstrip("\r\n")
        key = extract_key(line_no_nl)
        if key is not None and should_remove_key(key):
            removed_lines += 1
            removed_keys.append(normalize_key(key))
            continue
        output_lines.append(line)

    return "".join(output_lines), removed_lines, removed_keys


def process_file(path: Path, dry_run: bool, backup_ext: str) -> FileResult:
    raw = path.read_bytes()
    text, encoding = decode_text(raw)
    new_text, removed_lines, removed_keys = process_vmt_text(text)

    changed = new_text != text
    if changed and not dry_run:
        if backup_ext:
            backup_path = path.with_name(path.name + backup_ext)
            shutil.copy2(path, backup_path)
        path.write_text(new_text, encoding=encoding, newline="")

    return FileResult(
        path=path,
        changed=changed,
        removed_lines=removed_lines,
        removed_keys=removed_keys,
    )


def iter_vmt_files(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*.vmt") if p.is_file())


def main() -> int:
    args = parse_args()
    root = args.input_dir

    if not root.exists():
        print(f"Input directory does not exist: {root}", file=sys.stderr)
        return 1
    if not root.is_dir():
        print(f"Input path is not a directory: {root}", file=sys.stderr)
        return 1

    files = iter_vmt_files(root)
    if not files:
        print(f"No .vmt files found under: {root}")
        return 0

    changed_files = 0
    total_removed_lines = 0
    removed_key_counts: dict[str, int] = {}

    for path in files:
        result = process_file(path, dry_run=args.dry_run, backup_ext=args.backup_ext)
        if result.changed:
            changed_files += 1
            total_removed_lines += result.removed_lines
            for key in result.removed_keys:
                removed_key_counts[key] = removed_key_counts.get(key, 0) + 1

            if not args.quiet:
                rel = path.relative_to(root)
                mode = "would update" if args.dry_run else "updated"
                print(f"{mode}: {rel} (removed {result.removed_lines} line(s))")

    mode_label = "Dry run" if args.dry_run else "Done"
    print(
        f"{mode_label}: scanned {len(files)} .vmt file(s), "
        f"{changed_files} changed, {total_removed_lines} line(s) removed."
    )
    if removed_key_counts:
        for key, count in sorted(removed_key_counts.items()):
            print(f"  {key}: {count}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
