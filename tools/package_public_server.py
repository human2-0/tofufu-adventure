#!/usr/bin/env python3
"""Build a stripped server pack, preserving all physics and gameplay resources."""
import argparse
import hashlib
from pathlib import Path
import re
import subprocess
from verify import ROOT, find_godot


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    destination = args.destination.resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run([find_godot(), "--headless", "--path", str(ROOT),
                             "--export-pack", "Oracle Server", str(destination)],
                            capture_output=True, text=True, timeout=180)
    output = result.stdout + result.stderr
    destination.with_suffix(".build.log").write_text(output)
    if result.returncode or re.search(r"SCRIPT ERROR:|ERROR:", output):
        raise SystemExit(f"Server export failed; inspect {destination.with_suffix('.build.log')}")
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    destination.with_suffix(".sha256").write_text(f"{digest}  {destination.name}\n")
    print(f"Server pack: {destination} ({destination.stat().st_size:,} bytes)")
    print(f"SHA-256: {digest}")


if __name__ == "__main__":
    main()
