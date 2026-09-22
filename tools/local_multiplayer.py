#!/usr/bin/env python3
"""Run the dedicated meadow locally with private, persistent player profiles."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys

from verify import ROOT, find_godot


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path.home() / ".tofufu-local")
    commands = parser.add_subparsers(dest="command", required=True)
    setup = commands.add_parser("init", help="Create four player profiles once")
    setup.add_argument("--port", type=int, default=9080)
    commands.add_parser("server", help="Run until Ctrl-C; save before stopping")
    client = commands.add_parser("client", help="Open a player in the dedicated lobby")
    client.add_argument("player", type=int, choices=range(1, 5))
    commands.add_parser("stop", help="Ask the running server to save and stop")
    args = parser.parse_args()
    directory = args.directory.expanduser().resolve()
    if args.command == "init":
        if not 1 <= args.port <= 65535:
            parser.error("Port must be between 1 and 65535")
        subprocess.run([
            sys.executable, str(ROOT / "deploy/oracle/create_credentials.py"),
            str(directory), "--endpoint", f"ws://127.0.0.1:{args.port}",
        ], check=True)
        print("Ready. Start: python3 tools/local_multiplayer.py server")
        return
    if not (directory / "server.json").is_file():
        parser.error("Run init first, using the same --directory")
    state = directory / "world"
    state.mkdir(mode=0o700, exist_ok=True)
    stop_file = state / "stop-request"
    if args.command == "stop":
        stop_file.touch(mode=0o600)
        print("Requested checkpoint and server shutdown.")
        return
    env = os.environ.copy()
    command = [find_godot(), "--path", str(ROOT)]
    if args.command == "server":
        # Profiles are generated together; only read the endpoint to select the port.
        endpoint = json.loads((directory / "player-1.json").read_text())["endpoint"]
        env.update(TOFUFU_SERVER_CONFIG=str(directory / "server.json"),
                   TOFUFU_STATE_DIR=str(state), TOFUFU_SERVER_PORT=endpoint.rsplit(":", 1)[1])
        command += ["--headless", "--max-fps", "60", "res://game/app/dedicated_server.tscn"]
        print(f"World saves: {state}. Ctrl-C saves and stops the server.", flush=True)
    else:
        env["TOFUFU_CLIENT_CONFIG"] = str(directory / f"player-{args.player}.json")
        command += ["res://game/app/oracle_launch.tscn", "--", "--dedicated-lobby"]
        print(f"Player {args.player}: Connect to server, then Join meadow.", flush=True)
    process = subprocess.Popen(command, cwd=ROOT, env=env, start_new_session=True)
    try:
        return process.wait()
    except KeyboardInterrupt:
        if args.command == "server":
            stop_file.touch(mode=0o600)
            try:
                return process.wait(timeout=15)
            except subprocess.TimeoutExpired:
                print("Server did not finish its checkpoint; forcing shutdown.", file=sys.stderr)
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
        return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
