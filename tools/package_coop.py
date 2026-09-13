#!/usr/bin/env python3
"""Stage the current platform's Node/Holepunch runtime beside an exported game."""
import argparse
import json
from pathlib import Path
import os
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path, help='Directory containing the exported executable (macOS: Contents/MacOS)')
    parser.add_argument('--node', default=os.environ.get('TOFUFU_NODE_BIN') or shutil.which('node'))
    args = parser.parse_args()
    if not args.node:
        parser.error('Node.js 22+ is required; specify --node')
    node = Path(args.node).resolve()
    info = json.loads(subprocess.check_output([str(node), '-p', 'JSON.stringify({version:process.versions.node,platform:process.platform,arch:process.arch})'], text=True))
    if int(info['version'].split('.')[0]) < 22:
        parser.error('Node.js 22+ is required')
    source = ROOT / 'networking/sidecar'
    if not (source / 'node_modules/hyperswarm').exists():
        parser.error('Run npm ci --prefix networking/sidecar first')
    target = args.destination.resolve()
    target.mkdir(parents=True, exist_ok=True)
    runtime = target / 'networking/sidecar'
    executable = target / ('node.exe' if info['platform'] == 'win32' else 'node')
    if runtime.exists() or executable.exists():
        parser.error('A runtime already exists in this destination; choose a fresh staging directory')
    shutil.copytree(source / 'src', runtime / 'src')
    shutil.copytree(source / 'node_modules', runtime / 'node_modules', symlinks=False)
    for name in ('package.json', 'package-lock.json'):
        shutil.copy2(source / name, runtime / name)
    shutil.copy2(node, executable)
    (target / 'coop-runtime.json').write_text(json.dumps(info, indent=2) + '\n')
    print(f'Co-op runtime staged for {info["platform"]}/{info["arch"]}: {target}')
    print('Use this bundle only with a game export for the same platform/architecture. Apply platform signing after staging.')


if __name__ == '__main__':
    main()
