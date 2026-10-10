#!/usr/bin/env python3
"""Compare repeatable rendered scenes; timing checks are opt-in on the same device."""
import argparse
import json
import math
from pathlib import Path


def scenes(path):
    rows = json.loads(Path(path).read_text())
    result = {}
    for row in rows:
        if row.get("variant", "normal") != "normal":
            continue
        size = (row.get("render_width", 0), row.get("render_height", 0))
        if size != (2560, 1440):
            raise ValueError(f"Unverified 1440p render target: {size}")
        key = (row.get("mode", "solo_static"), row["place"], row.get("adaptive", False), row.get("camera_mode", "overhead"))
        if key in result:
            raise ValueError(f"Duplicate scene: {key}")
        for field in ("median_ms", "p95_ms", "triangles", "draws"):
            value = row[field]
            if not isinstance(value, (int, float)) or not math.isfinite(value) or value <= 0:
                raise ValueError(f"Invalid {field} in {key}")
        result[key] = row
    if not result:
        raise ValueError("No rendered scenes found")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--baseline", type=Path, default=Path(__file__).resolve().parents[1] / "tests/performance/m1_perspectives.json")
    parser.add_argument("--check-timings", action="store_true")
    args = parser.parse_args()
    before, after = scenes(args.baseline), scenes(args.candidate)
    failures = [f"Unexpected scene: {key}" for key in after.keys() - before.keys()]
    for key, expected in before.items():
        if key not in after:
            failures.append(f"Missing scene: {key}")
            continue
        fields = ["triangles", "draws"]
        if args.check_timings:
            fields += ["median_ms", "p95_ms"]
        for field in fields:
            tolerance = 1.25 if field.endswith("_ms") else 1.2
            if after[key][field] > expected[field] * tolerance:
                failures.append(f"{key} {field}: {expected[field]:.2f} -> {after[key][field]:.2f}")
    if failures:
        print("Render budget: FAIL\n" + "\n".join(failures))
        return 1
    print(f"Render budget: PASS ({len(before)} scenes; timing checks {'on' if args.check_timings else 'off'})")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, KeyError, OSError, TypeError) as error:
        raise SystemExit(f"Invalid benchmark: {error}")
