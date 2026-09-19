#!/usr/bin/env python3
"""Create private playtest credentials outside the repository; never print tokens."""
import argparse
import hashlib
import json
from pathlib import Path
import secrets

parser = argparse.ArgumentParser()
parser.add_argument("directory", type=Path)
parser.add_argument("--endpoint", required=True)
parser.add_argument("--players", type=int, default=4, choices=range(1, 33))
args = parser.parse_args()
if not args.endpoint.startswith(("wss://", "ws://127.0.0.1:")):
    parser.error("Use wss:// for public connections or ws://127.0.0.1:PORT for an SSH tunnel.")
args.directory.mkdir(mode=0o700, parents=True, exist_ok=False)
players = []
for number in range(1, args.players + 1):
    token = secrets.token_hex(32)
    players.append(hashlib.sha256(token.encode()).hexdigest())
    path = args.directory / f"player-{number}.json"
    path.write_text(json.dumps({"endpoint": args.endpoint, "token": token}, indent=2) + "\n")
    path.chmod(0o600)
path = args.directory / "server.json"
path.write_text(json.dumps({"server_id": secrets.token_hex(32), "players": players}, indent=2) + "\n")
path.chmod(0o600)
print(f"Created server.json and {args.players} private player files in {args.directory}")
