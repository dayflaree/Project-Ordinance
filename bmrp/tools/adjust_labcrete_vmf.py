#!/usr/bin/env python3
"""
Adjust LABCRETE texture axes in a VMF file.

For matching materials:
  - lab/labcrete00a
  - lab/labcrete00b
  - lab/labcrete00c

This script:
  - halves uaxis/vaxis scale (e.g. 0.25 -> 0.125)
  - adds 256 to uaxis/vaxis shift (4th value in the axis vector)
"""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


TARGET_MATERIALS = {
    "lab/labcrete00a",
    "lab/labcrete00b",
    "lab/labcrete00c",
}

BLOCK_NAME_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*$")
KEYVALUE_RE = re.compile(r'^(\s*)"([^"]+)"\s+"([^"]*)"(.*)$')
AXIS_VALUE_RE = re.compile(r"^\[([^\]]+)\]\s+([^\s]+)$")


def format_number(value: float) -> str:
    if abs(value) < 1e-12:
        value = 0.0
    rounded = round(value)
    if abs(value - rounded) < 1e-9:
        return str(int(rounded))
    return f"{value:.15g}"


def normalize_material(material: str) -> str:
    return material.strip().replace("\\", "/").lower()


def transform_axis_value(value: str, shift_add: float = 256.0) -> str:
    match = AXIS_VALUE_RE.match(value.strip())
    if not match:
        return value

    vector_parts = match.group(1).split()
    if len(vector_parts) != 4:
        return value

    try:
        shift = float(vector_parts[3])
        scale = float(match.group(2))
    except ValueError:
        return value

    vector_parts[3] = format_number(shift + shift_add)
    new_scale = format_number(scale / 2.0)
    return f"[{' '.join(vector_parts)}] {new_scale}"


def process_vmf(text: str) -> tuple[str, dict[str, int]]:
    lines = text.splitlines(keepends=True)
    out_lines: list[str] = []

    pending_block: str | None = None
    block_stack: list[str] = []
    side_targets: list[bool] = []

    stats = {
        "target_sides": 0,
        "uaxis_changed": 0,
        "vaxis_changed": 0,
    }

    for line in lines:
        line_ending = ""
        content = line
        if line.endswith("\r\n"):
            content = line[:-2]
            line_ending = "\r\n"
        elif line.endswith("\n"):
            content = line[:-1]
            line_ending = "\n"

        stripped = content.strip()

        if pending_block is not None and stripped == "{":
            block_name = pending_block.lower()
            block_stack.append(block_name)
            if block_name == "side":
                side_targets.append(False)
            pending_block = None
            out_lines.append(content + line_ending)
            continue

        if stripped == "}":
            if block_stack:
                ended = block_stack.pop()
                if ended == "side" and side_targets:
                    side_targets.pop()
            pending_block = None
            out_lines.append(content + line_ending)
            continue

        block_match = BLOCK_NAME_RE.match(content)
        if block_match:
            pending_block = block_match.group(1)
            out_lines.append(content + line_ending)
            continue

        if block_stack and block_stack[-1] == "side":
            keyvalue = KEYVALUE_RE.match(content)
            if keyvalue:
                indent, key, value, suffix = keyvalue.groups()
                key_lower = key.lower()

                if key_lower == "material" and side_targets:
                    if normalize_material(value) in TARGET_MATERIALS and not side_targets[-1]:
                        side_targets[-1] = True
                        stats["target_sides"] += 1

                if side_targets and side_targets[-1] and key_lower in {"uaxis", "vaxis"}:
                    new_value = transform_axis_value(value, shift_add=256.0)
                    if new_value != value:
                        content = f'{indent}"{key}" "{new_value}"{suffix}'
                        stats[f"{key_lower}_changed"] += 1

        out_lines.append(content + line_ending)

    return "".join(out_lines), stats


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Adjust LAB/LABCRETE00[A-C] texture axes in a VMF. "
            "Halves u/v scale and adds +256 to u/v shift."
        )
    )
    parser.add_argument("vmf_path", type=Path, help="Path to VMF file.")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Do not write file; only print what would change.",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Do not create a .bak file before writing.",
    )
    args = parser.parse_args()

    vmf_path = args.vmf_path
    if not vmf_path.is_file():
        raise SystemExit(f"File not found: {vmf_path}")

    with vmf_path.open("r", encoding="utf-8", errors="surrogateescape", newline="") as handle:
        original = handle.read()
    updated, stats = process_vmf(original)

    total_axis_changes = stats["uaxis_changed"] + stats["vaxis_changed"]
    print(f"Target sides: {stats['target_sides']}")
    print(f"uaxis changed: {stats['uaxis_changed']}")
    print(f"vaxis changed: {stats['vaxis_changed']}")
    print(f"Total axis lines changed: {total_axis_changes}")

    if args.dry_run:
        return 0

    if total_axis_changes == 0:
        print("No changes written.")
        return 0

    if not args.no_backup:
        backup_path = vmf_path.with_suffix(vmf_path.suffix + ".bak")
        shutil.copy2(vmf_path, backup_path)
        print(f"Backup written: {backup_path}")

    with vmf_path.open("w", encoding="utf-8", errors="surrogateescape", newline="") as handle:
        handle.write(updated)
    print(f"Updated file: {vmf_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
