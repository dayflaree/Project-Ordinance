#!/usr/bin/env python3
"""
Generate Parallax Scapes Lua registrations from a Source 1 soundscape KeyValues file.

Example:
    python tools/generate_scapes_from_soundscapes.py \
        --input "C:/.../soundscapes_rp_black_mesa_facility.txt" \
        --output "gamemode/schema/config/maps/rp_black_mesa_facility_generated.lua"
"""

from __future__ import annotations

import argparse
import re
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


@dataclass
class KVToken:
    kind: str
    value: str
    index: int


class KVParseError(RuntimeError):
    pass


def tokenize_kv(text: str) -> list[KVToken]:
    tokens: list[KVToken] = []
    i = 0
    n = len(text)

    while i < n:
        ch = text[i]

        if ch in " \t\r\n":
            i += 1
            continue

        if ch == "/" and i + 1 < n and text[i + 1] == "/":
            i += 2
            while i < n and text[i] != "\n":
                i += 1
            continue

        if ch == "{":
            tokens.append(KVToken("lbrace", ch, i))
            i += 1
            continue

        if ch == "}":
            tokens.append(KVToken("rbrace", ch, i))
            i += 1
            continue

        if ch == '"':
            start = i
            i += 1
            buf: list[str] = []
            while i < n:
                c = text[i]
                if c == "\\" and i + 1 < n:
                    nxt = text[i + 1]
                    if nxt in ['"', "\\"]:
                        buf.append(nxt)
                        i += 2
                        continue
                if c == '"':
                    i += 1
                    break
                buf.append(c)
                i += 1
            else:
                raise KVParseError(f"Unterminated string starting at index {start}")

            tokens.append(KVToken("string", "".join(buf), start))
            continue

        # Bare token fallback (rare in Valve KV files, but supported).
        start = i
        buf: list[str] = []
        while i < n and text[i] not in " \t\r\n{}":
            # Stop at comment start.
            if text[i] == "/" and i + 1 < n and text[i + 1] == "/":
                break
            buf.append(text[i])
            i += 1

        if buf:
            tokens.append(KVToken("string", "".join(buf), start))
            continue

        raise KVParseError(f"Unexpected character '{ch}' at index {i}")

    return tokens


class KVParser:
    def __init__(self, tokens: list[KVToken]) -> None:
        self.tokens = tokens
        self.index = 0

    def eof(self) -> bool:
        return self.index >= len(self.tokens)

    def peek(self) -> KVToken | None:
        if self.eof():
            return None
        return self.tokens[self.index]

    def pop(self) -> KVToken:
        token = self.peek()
        if token is None:
            raise KVParseError("Unexpected end of tokens")
        self.index += 1
        return token

    def expect(self, kind: str) -> KVToken:
        token = self.pop()
        if token.kind != kind:
            raise KVParseError(
                f"Expected token kind '{kind}', got '{token.kind}' at index {token.index}"
            )
        return token

    def parse_object(self, require_closing_brace: bool) -> list[tuple[str, str | list]]:
        items: list[tuple[str, str | list]] = []

        while not self.eof():
            token = self.peek()
            if token is None:
                break

            if token.kind == "rbrace":
                if require_closing_brace:
                    self.pop()
                    return items
                raise KVParseError(f"Unexpected '}}' at index {token.index}")

            key = self.expect("string").value
            value_token = self.peek()
            if value_token is None:
                raise KVParseError(f"Missing value for key '{key}'")

            if value_token.kind == "lbrace":
                self.pop()
                value = self.parse_object(require_closing_brace=True)
                items.append((key, value))
                continue

            value = self.expect("string").value
            items.append((key, value))

        if require_closing_brace:
            raise KVParseError("Missing closing brace '}'")

        return items


def parse_kv(text: str) -> list[tuple[str, str | list]]:
    tokens = tokenize_kv(text)
    parser = KVParser(tokens)
    return parser.parse_object(require_closing_brace=False)


def kv_get_first(items: list[tuple[str, str | list]], key: str) -> str | list | None:
    key_lower = key.lower()
    for k, v in items:
        if k.lower() == key_lower:
            return v
    return None


def kv_get_all(items: list[tuple[str, str | list]], key: str) -> list[str | list]:
    key_lower = key.lower()
    return [v for k, v in items if k.lower() == key_lower]


def normalize_sound_path(path: str) -> str:
    path = path.strip().replace("\\", "/")
    path = path.lstrip("/")
    return path


def parse_float(value: str | None, fallback: float) -> float:
    if not value:
        return fallback
    try:
        return float(value)
    except ValueError:
        return fallback


def parse_int(value: str | None, fallback: int) -> int:
    if not value:
        return fallback
    try:
        return int(float(value))
    except ValueError:
        return fallback


def parse_number_or_range(value: str | None, default: float | tuple[float, float]) -> float | tuple[float, float]:
    if value is None:
        return default

    raw = value.strip()
    if not raw:
        return default

    parts = [p.strip() for p in raw.split(",") if p.strip()]
    if len(parts) >= 2:
        try:
            a = float(parts[0])
            b = float(parts[1])
            lo, hi = (a, b) if a <= b else (b, a)
            return (lo, hi)
        except ValueError:
            return default

    try:
        return float(parts[0])
    except (ValueError, IndexError):
        return default


def parse_interval(value: str | None, default: tuple[float, float]) -> tuple[float, float]:
    parsed = parse_number_or_range(value, default)
    if isinstance(parsed, tuple):
        return parsed
    return (parsed, parsed)


def parse_soundlevel(value: str | None, fallback: int = 75) -> int:
    if not value:
        return fallback

    raw = value.strip()
    if not raw:
        return fallback

    db_match = re.search(r"(\d+)\s*dB", raw, re.IGNORECASE)
    if db_match:
        return int(db_match.group(1))

    token_match = re.search(r"SNDLVL_(\d+)", raw, re.IGNORECASE)
    if token_match:
        return int(token_match.group(1))

    try:
        return int(float(raw))
    except ValueError:
        return fallback


def parse_position(value: str | None) -> tuple[str, int | None]:
    if value is None:
        return ("ambient", None)

    raw = value.strip().lower()
    if not raw:
        return ("ambient", None)

    if raw == "random":
        return ("relative", None)

    if re.fullmatch(r"-?\d+", raw):
        key = int(raw)
        if 0 <= key <= 7:
            return ("positional", key)

    return ("ambient", None)


def sanitize_identifier(value: str) -> str:
    out = re.sub(r"[^a-zA-Z0-9_]+", "_", value)
    out = re.sub(r"_+", "_", out).strip("_")
    return out or "layer"


def fmt_float(value: float) -> str:
    s = f"{value:.4f}".rstrip("0").rstrip(".")
    if s == "-0":
        s = "0"
    if "." not in s:
        s += ".0"
    return s


def fmt_value(value: float | int | tuple[float, float], indent: str = "") -> str:
    if isinstance(value, tuple):
        return "{" + f"{fmt_float(value[0])}, {fmt_float(value[1])}" + "}"
    if isinstance(value, int):
        return str(value)
    return fmt_float(value)


def append_line(lines: list[str], text: str = "") -> None:
    lines.append(text)


def render_spatial(mode: str, position_key: int | None, sound_level: int, relative_radius: tuple[int, int]) -> str:
    if mode == "relative":
        return (
            "{ mode = \"relative\", radius = {"
            + f"{relative_radius[0]}, {relative_radius[1]}"
            + f"}}, hemisphere = true, soundLevel = {sound_level} }}"
        )

    if mode == "positional" and position_key is not None:
        return f"{{ mode = \"positional\", positionKey = {position_key}, soundLevel = {sound_level} }}"

    return f"{{ mode = \"ambient\", soundLevel = {sound_level} }}"


def emit_scape_register(
    scape_id: str,
    block: list[tuple[str, str | list]],
    *,
    mix_tag: str | None,
    priority: int,
    fade_in: float,
    fade_out: float,
    pause_legacy: bool,
    random_radius: tuple[int, int],
) -> str:
    lines: list[str] = []

    append_line(lines, f'ax.scapes:Register("{scape_id}", function(builder)')

    if mix_tag:
        append_line(lines, f'    builder:SetMixTag("{mix_tag}")')

    append_line(lines, f"    builder:SetPriority({priority})")
    append_line(lines, f"    builder:SetFade({fmt_float(fade_in)}, {fmt_float(fade_out)})")
    append_line(lines, f"    builder:SetPauseLegacyAmbient({'true' if pause_legacy else 'false'})")

    dsp_raw = kv_get_first(block, "dsp")
    if isinstance(dsp_raw, str) and dsp_raw.strip():
        append_line(lines, f'    builder:SetMixerProfile("dsp:{dsp_raw.strip()}")')

    layer_names = Counter()

    sub_scapes = [v for v in kv_get_all(block, "playsoundscape") if isinstance(v, list)]
    for sub in sub_scapes:
        name = kv_get_first(sub, "name")
        if not isinstance(name, str) or not name.strip():
            continue

        volume = parse_float(kv_get_first(sub, "volume") if isinstance(kv_get_first(sub, "volume"), str) else None, 1.0)
        pos_mode, pos_key = parse_position(kv_get_first(sub, "position") if isinstance(kv_get_first(sub, "position"), str) else None)

        if abs(volume - 1.0) < 1e-4 and not (pos_mode == "positional" and pos_key is not None):
            append_line(lines, f'    builder:AddSubScape("{name.strip()}")')
            continue

        append_line(lines, f'    builder:AddSubScape("{name.strip()}", {{')
        if abs(volume - 1.0) >= 1e-4:
            append_line(lines, f"        volumeMultiplier = {fmt_float(volume)},")
        if pos_mode == "positional" and pos_key is not None:
            append_line(lines, f"        forcePositionKey = {pos_key},")
        append_line(lines, "    })")

    loop_blocks = [v for v in kv_get_all(block, "playlooping") if isinstance(v, list)]
    for index, loop in enumerate(loop_blocks, start=1):
        wave = kv_get_first(loop, "wave")
        if not isinstance(wave, str) or not wave.strip():
            continue

        sound = normalize_sound_path(wave)
        vol = parse_number_or_range(kv_get_first(loop, "volume") if isinstance(kv_get_first(loop, "volume"), str) else None, 0.7)
        pitch = parse_number_or_range(kv_get_first(loop, "pitch") if isinstance(kv_get_first(loop, "pitch"), str) else None, 100)

        pos_mode, pos_key = parse_position(kv_get_first(loop, "position") if isinstance(kv_get_first(loop, "position"), str) else None)
        sound_level = parse_soundlevel(kv_get_first(loop, "soundlevel") if isinstance(kv_get_first(loop, "soundlevel"), str) else None, 75)

        base_name = sanitize_identifier(Path(sound).stem)
        if pos_mode == "positional" and pos_key is not None:
            base_name = f"{base_name}_pos{pos_key}"
        elif pos_mode == "relative":
            base_name = f"{base_name}_rel"

        layer_names[base_name] += 1
        layer_name = base_name if layer_names[base_name] == 1 else f"{base_name}_{layer_names[base_name]}"

        append_line(lines, f'    builder:AddLoop("{layer_name}", {{')
        append_line(lines, f'        sounds = "{sound}",')
        append_line(lines, f"        volume = {fmt_value(vol)},")
        append_line(lines, f"        pitch = {fmt_value(pitch)},")
        append_line(lines, f"        spatial = {render_spatial(pos_mode, pos_key, sound_level, random_radius)},")
        append_line(lines, "        preload = true,")
        append_line(lines, "    })")

    random_blocks = [v for v in kv_get_all(block, "playrandom") if isinstance(v, list)]
    for index, rnd in enumerate(random_blocks, start=1):
        rndwave = kv_get_first(rnd, "rndwave")
        sounds: list[str] = []
        if isinstance(rndwave, list):
            for key, value in rndwave:
                if key.lower() == "wave" and isinstance(value, str) and value.strip():
                    sounds.append(normalize_sound_path(value))

        if not sounds:
            continue

        vol = parse_number_or_range(kv_get_first(rnd, "volume") if isinstance(kv_get_first(rnd, "volume"), str) else None, (0.3, 0.6))
        pitch = parse_number_or_range(kv_get_first(rnd, "pitch") if isinstance(kv_get_first(rnd, "pitch"), str) else None, (95, 105))
        interval = parse_interval(kv_get_first(rnd, "time") if isinstance(kv_get_first(rnd, "time"), str) else None, (8.0, 16.0))

        pos_mode, pos_key = parse_position(kv_get_first(rnd, "position") if isinstance(kv_get_first(rnd, "position"), str) else None)
        sound_level = parse_soundlevel(kv_get_first(rnd, "soundlevel") if isinstance(kv_get_first(rnd, "soundlevel"), str) else None, 90)

        layer_name = f"legacy_random_{index}"
        append_line(lines, f'    builder:AddRandom("{layer_name}", {{')
        append_line(lines, "        sounds = {")
        for sound in sounds:
            append_line(lines, f'            "{sound}",')
        append_line(lines, "        },")
        append_line(lines, f"        volume = {fmt_value(vol)},")
        append_line(lines, f"        pitch = {fmt_value(pitch)},")
        append_line(lines, f"        interval = {fmt_value(interval)},")
        append_line(lines, f"        spatial = {render_spatial(pos_mode, pos_key, sound_level, random_radius)},")
        append_line(lines, "        limit = { instance = 1, blockDistance = 512 },")
        append_line(lines, "    })")

    append_line(lines, "end)")

    return "\n".join(lines)


def build_output(
    root_items: list[tuple[str, str | list]],
    *,
    mix_tag: str | None,
    priority: int,
    fade_in: float,
    fade_out: float,
    pause_legacy: bool,
    random_radius: tuple[int, int],
    dedupe: str,
    skip_empty: bool,
    source_path: Path,
) -> tuple[str, dict[str, int]]:
    scapes: list[tuple[str, list[tuple[str, str | list]]]] = []

    for key, value in root_items:
        if not isinstance(value, list):
            continue
        scapes.append((key, value))

    if dedupe != "none":
        by_id: dict[str, list[tuple[str, str | list]]] = {}
        order: list[str] = []

        if dedupe == "first":
            for scape_id, block in scapes:
                if scape_id in by_id:
                    continue
                by_id[scape_id] = block
                order.append(scape_id)
        else:
            # last
            for scape_id, block in scapes:
                if scape_id not in by_id:
                    order.append(scape_id)
                by_id[scape_id] = block

            # preserve final-order by scanning original list backwards.
            seen = set()
            final_order: list[str] = []
            for scape_id, _ in reversed(scapes):
                if scape_id in seen:
                    continue
                seen.add(scape_id)
                final_order.append(scape_id)
            order = list(reversed(final_order))

        scapes = [(scape_id, by_id[scape_id]) for scape_id in order]

    emitted = 0
    skipped = 0
    blocks: list[str] = []

    for scape_id, block in scapes:
        loop_count = len([v for v in kv_get_all(block, "playlooping") if isinstance(v, list)])
        rnd_count = len([v for v in kv_get_all(block, "playrandom") if isinstance(v, list)])
        sub_count = len([v for v in kv_get_all(block, "playsoundscape") if isinstance(v, list)])

        if skip_empty and loop_count == 0 and rnd_count == 0 and sub_count == 0:
            skipped += 1
            continue

        blocks.append(
            emit_scape_register(
                scape_id,
                block,
                mix_tag=mix_tag,
                priority=priority,
                fade_in=fade_in,
                fade_out=fade_out,
                pause_legacy=pause_legacy,
                random_radius=random_radius,
            )
        )
        emitted += 1

    header = [
        "-- Auto-generated by tools/generate_scapes_from_soundscapes.py",
        f"-- Source: {source_path.as_posix()}",
        f"-- Scapes emitted: {emitted}",
        "",
    ]

    output = "\n\n".join(["\n".join(header)] + blocks) + "\n"

    stats = {
        "total_top_level": len([1 for _, v in root_items if isinstance(v, list)]),
        "emitted": emitted,
        "skipped": skipped,
    }
    return output, stats


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, help="Input Source 1 soundscape txt file.")
    parser.add_argument("--output", required=True, help="Output Lua file path.")
    parser.add_argument("--mix-tag", default="facility", help="Default mix tag to set on each generated scape.")
    parser.add_argument("--no-mix-tag", action="store_true", help="Do not emit builder:SetMixTag().")
    parser.add_argument("--priority", type=int, default=30, help="Default priority for generated scapes.")
    parser.add_argument("--fade-in", type=float, default=1.0, help="Default fade-in seconds.")
    parser.add_argument("--fade-out", type=float, default=1.0, help="Default fade-out seconds.")
    parser.add_argument(
        "--pause-legacy-ambient",
        action="store_true",
        default=True,
        help="Emit builder:SetPauseLegacyAmbient(true).",
    )
    parser.add_argument(
        "--no-pause-legacy-ambient",
        action="store_true",
        help="Emit builder:SetPauseLegacyAmbient(false).",
    )
    parser.add_argument(
        "--random-relative-radius",
        default="256,768",
        help="Default radius range for 'position=random' (min,max).",
    )
    parser.add_argument(
        "--dedupe",
        choices=["first", "last", "none"],
        default="last",
        help="How to handle duplicate top-level soundscape IDs.",
    )
    parser.add_argument(
        "--skip-empty",
        action="store_true",
        help="Skip top-level scapes that have no playlooping/playrandom/playsoundscape blocks.",
    )
    return parser.parse_args()


def parse_radius_pair(raw: str) -> tuple[int, int]:
    parts = [p.strip() for p in raw.split(",") if p.strip()]
    if len(parts) < 2:
        raise ValueError("--random-relative-radius must be in 'min,max' format")

    a = int(float(parts[0]))
    b = int(float(parts[1]))
    lo, hi = (a, b) if a <= b else (b, a)
    return lo, hi


def main() -> int:
    args = parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.exists():
        raise SystemExit(f"Input file does not exist: {input_path}")

    text = input_path.read_text(encoding="utf-8", errors="ignore")
    parsed = parse_kv(text)

    mix_tag = None if args.no_mix_tag else args.mix_tag
    pause_legacy = False if args.no_pause_legacy_ambient else bool(args.pause_legacy_ambient)
    random_radius = parse_radius_pair(args.random_relative_radius)

    output, stats = build_output(
        parsed,
        mix_tag=mix_tag,
        priority=args.priority,
        fade_in=args.fade_in,
        fade_out=args.fade_out,
        pause_legacy=pause_legacy,
        random_radius=random_radius,
        dedupe=args.dedupe,
        skip_empty=args.skip_empty,
        source_path=input_path,
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(output, encoding="utf-8")

    print(f"Input top-level blocks: {stats['total_top_level']}")
    print(f"Scapes emitted: {stats['emitted']}")
    print(f"Scapes skipped: {stats['skipped']}")
    print(f"Wrote: {output_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
