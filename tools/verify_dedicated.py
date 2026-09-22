#!/usr/bin/env python3
"""Local dedicated server + two real launcher processes, restart and saved identities."""
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import sys
import tempfile
import time

from verify import ROOT, find_godot


def wait_for(predicate, processes, seconds=25):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if predicate():
            return
        if any(process.poll() is not None for process in processes):
            raise RuntimeError("A peer exited before the expected state")
        time.sleep(0.05)
    raise RuntimeError("Dedicated process verification timed out")


def main():
    directory = Path(tempfile.mkdtemp(prefix="tofufu-dedicated-"))
    print(f"Logs and checkpoints: {directory}", flush=True)
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    profiles = directory / "profiles"
    subprocess.run([sys.executable, str(ROOT / "deploy/oracle/create_credentials.py"),
                    str(profiles), "--endpoint", f"ws://127.0.0.1:{port}"], check=True)
    state = directory / "world"
    state.mkdir()
    processes, handles = [], []

    def start(name, args, settings):
        log = directory / f"{name}.log"
        handle = log.open("w")
        handles.append(handle)
        env = os.environ.copy()
        for key in ("TOFUFU_SERVER_CONFIG", "TOFUFU_CLIENT_CONFIG", "TOFUFU_STATE_DIR", "TOFUFU_SERVER_PORT"):
            env.pop(key, None)
        env.update(settings)
        process = subprocess.Popen([find_godot(), "--headless", "--path", str(ROOT),
                                    "--max-fps", "60", *args], cwd=ROOT, env=env,
                                   stdout=handle, stderr=subprocess.STDOUT)
        processes.append(process)
        return process, log

    try:
        previous = None
        for run in range(2):
            phase = directory / str(run)
            phase.mkdir()
            server, log = start(f"server-{run}", ["res://game/app/dedicated_server.tscn"], {
                "TOFUFU_SERVER_CONFIG": str(profiles / "server.json"),
                "TOFUFU_STATE_DIR": str(state), "TOFUFU_SERVER_PORT": str(port)})
            wait_for(lambda: "ORACLE_READY" in log.read_text(), [server])
            clients = []
            for player in (1, 2):
                client, _ = start(f"client-{run}-{player}", ["--script", "res://tests/test_dedicated_peer.gd"], {
                    "TOFUFU_CLIENT_CONFIG": str(profiles / f"player-{player}.json"),
                    "TOFUFU_TEST_PLAYER": str(player), "TOFUFU_TEST_RESULT": str(phase / f"{player}.json")})
                clients.append(client)
            wait_for(lambda: all((phase / f"{p}.json").exists() for p in (1, 2)), [server, *clients])
            (phase / "release").touch()
            for client in clients:
                if client.wait(timeout=10) != 0:
                    raise RuntimeError("Client verification failed")
            # Leaving all players must keep the world alive, then managed stop saves it.
            if server.poll() is not None:
                raise RuntimeError("Empty server unexpectedly stopped")
            (state / "stop-request").touch()
            if server.wait(timeout=10) != 0:
                raise RuntimeError("Server checkpoint shutdown failed")
            checkpoint = json.loads((state / "adventure_00.json").read_text())
            party = checkpoint["coop"]["party"]
            if len(party) != 2:
                raise RuntimeError("Server did not retain exactly two player records")
            for player in (1, 2):
                result = json.loads((phase / f"{player}.json").read_text())
                token = json.loads((profiles / f"player-{player}.json").read_text())["token"]
                identity = hashlib.sha256(token.encode()).hexdigest()
                if result["identity"] != identity or identity not in party:
                    raise RuntimeError("Authenticated identity was not persisted")
                if previous:
                    old = previous[identity]["position"]
                    if sum((a-b)**2 for a, b in zip(result["initial"], old)) > 1.6:
                        raise RuntimeError("Restart did not restore the player near their saved position")
            previous = party
        for log in directory.glob("*.log"):
            if re.search(r"SCRIPT ERROR:|ERROR:|FAIL:", log.read_text()):
                raise RuntimeError(f"Engine error in {log}")
        print("Dedicated separate-process launch, movement, leave, checkpoint and restart: PASS")
    finally:
        for process in processes:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
        for handle in handles:
            handle.close()


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
