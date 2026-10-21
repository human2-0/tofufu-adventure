"""Read source pixels; write atlas bounds and Godot resources without editing PNGs."""
from pathlib import Path
import json
from statistics import median
from PIL import Image
import numpy as np
import runpy

ROOT = Path(__file__).parent
DIRECTIONS = ['n', 'nw', 'w', 'sw', 's']
PHASES = ['takeoff', 'push_off', 'ascent', 'apex', 'fall_start', 'mid_fall',
          'pre_landing', 'landing_impact', 'rebound', 'settled']
KINDS = {'locomotion': ['idle', 'walk_0', 'walk_1', 'walk_2', 'walk_3'],
         'jump': PHASES, 'melee': ['jab', 'cross', 'uppercut', 'kick']}


def body_center(alpha, bounds):
    """Register the solid torso, excluding stepping toes, arms and accessories."""
    x0, y0, x1, y1 = bounds
    height = y1 - y0
    top, bottom = y0 + int(height * .32), y0 + int(height * .62)
    coverage = (alpha[top:bottom, x0:x1] >= 128).mean(axis=0) >= .8
    edges = np.diff(np.r_[False, coverage, False].astype(int))
    spans = list(zip(np.where(edges == 1)[0], np.where(edges == -1)[0]))
    assert spans, 'expected a solid torso in every pose'
    left, right = max(spans, key=lambda span: span[1] - span[0])
    return x0 + (left + right - 1) * .5


def inspect(path, columns):
    with Image.open(path) as im:
        assert im.mode == 'RGBA', f'{path}: expected real alpha'
        alpha = im.getchannel('A')
        assert alpha.getextrema() == (0, 255), f'{path}: missing transparency'
        width, height = im.size
        component_reader = runpy.run_path(str(ROOT.parent / 'fufu/unarmed/calibrate.py'))['components']
        boxes = component_reader(np.asarray(alpha) >= 128)
        assert len(boxes) == columns * 5, f'{path}: expected {columns * 5} characters, found {len(boxes)}'
        by_column = [[] for _ in range(columns)]
        for box in boxes:
            column = min(columns - 1, int((box[0] + box[2]) * 0.5 / width * columns))
            by_column[column].append(box)
        for column in by_column:
            column.sort(key=lambda b: b[1])
            assert len(column) == 5, f'{path}: each column must contain five angles'
        frames = []
        for row, direction in enumerate(DIRECTIONS):
            for col in range(columns):
                x0, y0, x1, y1 = by_column[col][row]
                rx, ry = max(0, x0 - 3), max(0, y0 - 3)
                right, bottom = min(width, x1 + 3), min(height, y1 + 3)
                foot_mask = np.asarray(alpha)[max(y0, y1 - 8):y1, x0:x1] >= 128
                _, foot_x = np.where(foot_mask)
                foot_center = float(np.median(foot_x)) + x0 if len(foot_x) else (x0 + x1) / 2
                frames.append({'direction': direction, 'phase': col,
                    'region': [rx, ry, right - rx, bottom - ry],
                    'painted_bounds': [x0 - rx, y0 - ry, x1 - x0, y1 - y0],
                    'center': body_center(np.asarray(alpha), (x0, y0, x1, y1)) - rx,
                    'foot_center': foot_center - rx, 'feet': y1 - 1 - ry,
                    'edge_contact': x0 == 0 or y0 == 0 or x1 == width or y1 == height})
        return frames


def resource(folder, sheets):
    lines = ['[gd_resource type="SpriteFrames" load_steps=100 format=3]', '']
    textures, animations = [], []
    for kind, frames in sheets.items():
        lines += [f'[ext_resource type="Texture2D" path="res://assets/characters/tofufu/{folder.name}/{kind}.png" id="{kind}"]', '']
    for kind, frames in sheets.items():
        for index, frame in enumerate(frames):
            ident = f'{kind}_{index}'
            region = ', '.join(str(v) for v in frame['region'])
            lines += [f'[sub_resource type="AtlasTexture" id="{ident}"]',
                      f'atlas = ExtResource("{kind}")', f'region = Rect2({region})',
                      f'margin = Rect2({256 - frame["center"]}, {448 - frame["feet"]}, {512 - frame["region"][2]}, {512 - frame["region"][3]})',
                      'filter_clip = true', '']
            textures.append(ident)
        for row, direction in enumerate(DIRECTIONS):
            groups = {'idle': [0], 'walk': [1, 2, 3, 4]} if kind == 'locomotion' else (
                {'jump': list(range(10))} if kind == 'jump' else
                {phase: [i] for i, phase in enumerate(KINDS[kind])})
            for animation, columns in groups.items():
                ids = [f'{kind}_{row * len(KINDS[kind]) + col}' for col in columns]
                body = ', '.join('{"duration": 1.0, "texture": SubResource("' + ident + '")}' for ident in ids)
                loop = 'true' if animation in ['idle', 'walk'] else 'false'
                animations.append('{"frames": [' + body + '], "loop": ' + loop +
                                  ', "name": &"' + animation + '_' + direction + '", "speed": 9.0}')
    lines[0] = f'[gd_resource type="SpriteFrames" load_steps={1 + len(sheets) + len(textures)} format=3]'
    lines += ['[resource]', 'animations = [' + ',\n'.join(animations) + ']', '']
    (folder / 'animations.tres').write_text('\n'.join(lines))


def build(folder):
    sheets = {}
    for kind, phases in KINDS.items():
        path = folder / f'{kind}.png'
        if path.exists():
            frames = inspect(path, len(phases))
            rest_col = 0 if kind != 'jump' else 9
            heights = [frame['painted_bounds'][3] for frame in frames if frame['phase'] == rest_col]
            scale = 1.12 / median(heights)
            for frame in frames:
                frame['phase_name'] = phases[frame['phase']]
                frame['pixel_size'] = scale
            sheets[kind] = frames
    layout = {'authored_directions': DIRECTIONS,
              'mirrored_directions': {'ne': 'nw', 'e': 'w', 'se': 'sw'},
              'mirror_property': 'flip_h', 'target_standing_height_world': 1.12,
              'horizontal_anchor': 'solid torso center; feet define vertical baseline only',
              'jump_phases': PHASES, 'sheets': sheets}
    (folder / 'sprite-layout.json').write_text(json.dumps(layout, indent=2) + '\n')
    resource(folder, sheets)
    contacts = [(kind, f['direction'], f['phase']) for kind, frames in sheets.items() for f in frames if f['edge_contact']]
    print(folder.name, {kind: len(frames) for kind, frames in sheets.items()}, 'cell edge contacts:', contacts)


if __name__ == '__main__':
    for folder in sorted(ROOT.iterdir()):
        if folder.is_dir() and (folder / 'source/walk-original.png').exists():
            build(folder)
