#!/usr/bin/env python3
"""Three real peers, isolated DHT, plant selection, optional duos and paused migration."""
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
import time
import uuid
from verify import ROOT, find_godot


def stop(process):
    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=4)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cpus', type=int, choices=range(51), default=19)
    parser.add_argument('--difficulty', choices=['easy', 'normal', 'hard'], default='normal')
    parser.add_argument('--duos', action='store_true', help='pair friends and CPUs; exercise shared plant reservations')
    options = parser.parse_args()
    skill = ['easy', 'normal', 'hard'].index(options.difficulty)
    cpus = options.cpus
    if options.duos and (3 + cpus) % 2:
        cpus += 1 if cpus < 50 else -1
    actors = 3 + cpus
    expected_options = [options.cpus, skill] + ([1] if options.duos else [])
    node = os.environ.get('TOFUFU_NODE_BIN') or shutil.which('node')
    if not node:
        raise RuntimeError('Node.js 22+ is required')
    directory = Path(tempfile.mkdtemp(prefix='tofufu-battle-peers-'))
    print(f'Battle peer logs: {directory}', flush=True)
    env = dict(os.environ, TOFUFU_NODE_BIN=node, TOFUFU_TEST_TOPIC=uuid.uuid4().hex,
               TOFUFU_BATTLE_PROBE_DIRECTORY=str(directory), TOFUFU_BATTLE_PROBE_CPUS=str(options.cpus),
               TOFUFU_BATTLE_PROBE_SKILL=str(skill), TOFUFU_BATTLE_PROBE_DUOS=str(int(options.duos)))
    processes, handles, peers = [], [], {}
    try:
        bootstrap = subprocess.Popen([node, 'networking/sidecar/test/bootstrap.cjs'], cwd=ROOT,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        processes.append(bootstrap)
        output = queue.Queue()
        threading.Thread(target=lambda: output.put(bootstrap.stdout.readline()), daemon=True).start()
        env['TOFUFU_TEST_DHT'] = json.loads(output.get(timeout=10))['address']

        def launch(role, host=''):
            log = (directory / f'{role}.log').open('w')
            handles.append(log)
            process = subprocess.Popen([find_godot(), '--headless', '--path', str(ROOT), '--script',
                                        'res://tests/battle_peer_probe.gd'], cwd=ROOT,
                                       env=dict(env, TOFUFU_BATTLE_PROBE_ROLE=role, TOFUFU_BATTLE_PROBE_HOST=host),
                                       stdout=log, stderr=log)
            peers[role] = process
            processes.append(process)

        def statuses(roles):
            result = {}
            for role in roles:
                if peers[role].poll() is not None:
                    raise RuntimeError(f'{role} exited: {(directory / (role + ".log")).read_text()}')
                try:
                    result[role] = json.loads((directory / f'{role}.json').read_text())
                except (FileNotFoundError, json.JSONDecodeError):
                    return {}
            return result

        launch('p0')
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            initial = statuses(['p0'])
            if initial.get('p0', {}).get('key'):
                break
            time.sleep(.1)
        else:
            raise RuntimeError('Initial battle peer did not start')
        host_key = initial['p0']['key']
        launch('p1', host_key)
        launch('p2', host_key)
        deadline = time.monotonic() + 240
        while time.monotonic() < deadline:
            before = statuses(peers)
            if len(before) == 3 and all(row['phase'] == 'playing' and row['checkpoint'] > 0 and row['bodies'] == actors
                                        and row.get('options') == expected_options and row['cpus'] == actors - 3
                                        and row.get('mob_count', 0) >= 15 and row.get('first_mob_dead') and row.get('hunt_claims', 0) >= 1
                                        and row.get('deployment_stage') == 2 and row.get('apples') == 6 and row.get('opened_chests', 0) >= 1
                                        and row.get('apple_seconds', 0) > 0 for row in before.values()):
                break
            time.sleep(.2)
        else:
            raise RuntimeError('Three battle peers did not synchronize')
        assert {row['host'] for row in before.values()} == {host_key}
        if options.duos:
            assert all(row['plants'][0] == row['plants'][1] and row['plants'][0] != row['plants'][2] for row in before.values())
        print(f'Three real peers / {actors} actors / {options.difficulty} CPUs / shared checkpoints: PASS', flush=True)
        peers['p0'].kill()
        peers['p0'].wait(timeout=5)
        paused = set()
        deadline = time.monotonic() + 45
        while time.monotonic() < deadline:
            after = statuses(['p1', 'p2'])
            paused.update(role for role, row in after.items() if row['phase'] == 'recovering')
            if len(after) == 2 and all(row['phase'] == 'playing' and row['term'] == 1 and row['cpus'] == actors - 2 and row.get('options') == expected_options for row in after.values()):
                break
            time.sleep(.1)
        else:
            raise RuntimeError('Peers did not recover from abrupt authority loss')
        assert len({row['host'] for row in after.values()}) == 1
        assert all(row['host'] != host_key and row['bodies'] == actors for row in after.values())
        assert all(row.get('mob_count', 0) >= 15 and row.get('first_mob_dead') and row.get('hunt_claims', 0) >= 1 for row in after.values())
        assert all(row.get('apples') == 6 and 0 < row.get('apple_seconds', 0) <= 25
                   and row.get('opened_chests', 0) >= 1 and row.get('drop_slots', 0) >= 4 for row in after.values())
        assert all(row.get('deployment_stage') == 2 and row.get('plants') == before['p0']['plants'] for row in after.values())
        assert paused == {'p1', 'p2'}, 'both peers must visibly enter paused recovery'
        (directory / 'finish').touch()
        for role in ['p1', 'p2']:
            peers[role].wait(timeout=10)
            text = (directory / f'{role}.log').read_text()
            if peers[role].returncode or re.search(r'SCRIPT ERROR:|ERROR:|FAIL:', text):
                raise RuntimeError(f'{role} failed: {text}')
        report = {'passed': True, 'scope': 'Three OS processes and real encrypted Holepunch over an isolated loopback DHT; abrupt host kill, paused recovery, new authority, plant reservation and duo settings, selected actor count and CPU difficulty, CPU replacement, consumed backpack apples, ongoing healing, opened chest/drop recovery and finite hunt death/credit recovery. Not WAN/NAT acceptance.',
                  'duos': options.duos, 'effective_cpus': cpus, 'requested_cpus': options.cpus, 'difficulty': options.difficulty, 'actor_count': actors, 'before': before, 'after': after, 'observed_paused': sorted(paused), 'logs': str(directory)}
        (directory / 'result.json').write_text(json.dumps(report, indent=2))
        print('Abrupt host loss / paused migration / CPU replacement: PASS', flush=True)
        print(f'Result: {directory / "result.json"}', flush=True)
    finally:
        for process in reversed(processes):
            stop(process)
        for handle in handles:
            handle.close()


if __name__ == '__main__':
    main()
