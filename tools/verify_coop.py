#!/usr/bin/env python3
"""Two Godot processes + real Holepunch; isolated DHT by default, public opt-in."""
import argparse
import json
import os
from pathlib import Path
import queue
import re
import shutil
import subprocess
import tempfile
import threading
import uuid
from verify import ROOT, find_godot


def stop(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--public-network', action='store_true')
    args = parser.parse_args()
    node = os.environ.get('TOFUFU_NODE_BIN') or shutil.which('node')
    if not node:
        raise RuntimeError('Node.js 22+ is required')
    directory = Path(tempfile.mkdtemp(prefix='tofufu-coop-'))
    print(f'Co-op logs: {directory}', flush=True)
    env = dict(os.environ, TOFUFU_NODE_BIN=node, TOFUFU_TEST_DIRECTORY=str(directory), TOFUFU_TEST_TOPIC=uuid.uuid4().hex)
    processes = []
    handles = []
    try:
        if not args.public_network:
            bootstrap = subprocess.Popen([node, 'networking/sidecar/test/bootstrap.cjs'], cwd=ROOT,
                                         stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            processes.append(bootstrap)
            output = queue.Queue()
            threading.Thread(target=lambda: output.put(bootstrap.stdout.readline()), daemon=True).start()
            env['TOFUFU_TEST_DHT'] = json.loads(output.get(timeout=10))['address']
        else:
            env.pop('TOFUFU_TEST_DHT', None)

        def launch(role):
            log = (directory / f'{role}.log').open('w')
            handles.append(log)
            process = subprocess.Popen([find_godot(), '--headless', '--path', str(ROOT),
                                        '--script', 'res://tests/test_coop_peer.gd'], cwd=ROOT,
                                       env=dict(env, TOFUFU_TEST_ROLE=role), stdout=log, stderr=log)
            processes.append(process)
            return process

        host, guest = launch('host'), launch('guest')
        guest.wait(timeout=40)
        returning = launch('returning')
        returning.wait(timeout=30)
        host.wait(timeout=15)
        for handle in handles:
            handle.flush()
        for role, process in [('host', host), ('guest', guest), ('returning', returning)]:
            log = (directory / f'{role}.log').read_text()
            if process.returncode or re.search(r'SCRIPT ERROR:|ERROR:|FAIL:', log):
                raise RuntimeError(f'{role} failed:\n{log}')
            result = json.loads((directory / f'{role}.json').read_text())
            if result['failures']:
                raise RuntimeError(f'{role} assertions failed')
            print(f'{role}: PASS', flush=True)
        first = json.loads((directory / 'guest.json').read_text())
        second = json.loads((directory / 'returning.json').read_text())
        assert first['key'] == second['key'], 'persistent identity changed across process restart'
        print('Two-process co-op, reconnect, host save and clean shutdown: PASS', flush=True)
    finally:
        for process in reversed(processes):
            stop(process)
        for handle in handles:
            handle.close()


if __name__ == '__main__':
    main()
