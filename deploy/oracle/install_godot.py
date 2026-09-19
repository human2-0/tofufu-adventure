#!/usr/bin/env python3
"""Install the pinned official Linux runtime after verifying its published SHA-512."""
import argparse
import hashlib
import os
from pathlib import Path
import platform
import tempfile
import urllib.request
import zipfile

VERSION = "4.7.2"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    arch = {"x86_64": "x86_64", "aarch64": "arm64"}.get(platform.machine())
    if arch is None:
        raise SystemExit("This installer supports Linux x86_64 and aarch64.")
    name = f"Godot_v{VERSION}-stable_linux.{arch}"
    base = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/"
    with tempfile.TemporaryDirectory() as directory:
        archive = Path(directory) / (name + ".zip")
        urllib.request.urlretrieve(base + archive.name, archive)
        sums = urllib.request.urlopen(base + "SHA512-SUMS.txt", timeout=60).read().decode()
        expected = next((line.split()[0] for line in sums.splitlines()
                         if line.split() and line.split()[-1].lstrip("*") == archive.name), None)
        if expected is None or hashlib.sha512(archive.read_bytes()).hexdigest() != expected:
            raise SystemExit("Official runtime checksum verification failed.")
        args.destination.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(archive) as source:
            with source.open(name) as binary:
                args.destination.write_bytes(binary.read())
        os.chmod(args.destination, 0o755)


if __name__ == "__main__":
    main()
