"""Read the untouched RGBA sources and write non-destructive Godot crop metadata."""
from pathlib import Path
import json
from statistics import median

import numpy as np
from PIL import Image

ROOT = Path(__file__).parent
HEIGHTS = {"base": 1.18, "bright_leaf": 1.12, "dark_leaf": 1.12, "celestial": 1.17}


def components(alpha):
    parents, boxes, counts = [], [], []

    def root(index):
        while parents[index] != index:
            parents[index] = parents[parents[index]]
            index = parents[index]
        return index

    previous = []
    for y, pixels in enumerate(alpha):
        changes = np.diff(np.pad(pixels.astype(np.int8), (1, 1)))
        starts, ends = np.where(changes == 1)[0], np.where(changes == -1)[0]
        current = []
        for left, right in zip(starts, ends):
            matches = {root(index) for a, b, index in previous if a <= right and b >= left}
            if matches:
                index = min(matches)
                for other in matches - {index}:
                    parents[other] = index
                    boxes[index] = [min(boxes[index][0], boxes[other][0]), min(boxes[index][1], boxes[other][1]), max(boxes[index][2], boxes[other][2]), max(boxes[index][3], boxes[other][3])]
                    counts[index] += counts[other]
            else:
                index = len(parents)
                parents.append(index)
                boxes.append([int(left), y, int(right), y + 1])
                counts.append(0)
            boxes[index][0] = min(boxes[index][0], int(left))
            boxes[index][2] = max(boxes[index][2], int(right))
            boxes[index][3] = y + 1
            counts[index] += int(right - left)
            current.append((left, right, index))
        previous = current
    return [box for index, box in enumerate(boxes) if root(index) == index and counts[index] > 1500]


def calibrate(outfit):
    with Image.open(ROOT / (outfit + ".png")) as image:
        alpha = np.asarray(image.getchannel("A")) > 128
        width, height = image.size
    found = components(alpha)
    if len(found) != 20:
        raise ValueError(f"{outfit}: expected 20 separate complete characters, got {len(found)}: {found}")
    columns = [[] for _ in range(4)]
    for box in found:
        column = min(3, int((box[0] + box[2]) * 0.5 / width * 4))
        columns[column].append(box)
    for column in columns:
        column.sort(key=lambda box: box[1])
        if len(column) != 5:
            raise ValueError(f"{outfit}: each attack column needs all five viewing angles")
    scale = HEIGHTS[outfit] / median(box[3] - box[1] for box in found)
    result = []
    for row in range(5):
        for style in range(4):
            box = columns[style][row]
            x0, y0 = max(0, box[0] - 4), max(0, box[1] - 4)
            x1, y1 = min(width, box[2] + 4), min(height, box[3] + 4)
            if row:
                y0 = max(y0, (columns[style][row - 1][3] + box[1]) // 2)
            if row < 4:
                y1 = min(y1, (box[3] + columns[style][row + 1][1]) // 2)
            feet = box[3] - 1
            foot_y, foot_x = np.where(alpha[max(box[1], feet - 8):feet + 1, box[0]:box[2]])
            center = float(np.median(foot_x)) + box[0]
            # Wrists are supplied before runtime mirroring, including the opposite arm.
            right_x = [0.26, 0.27, 0.32, 0.73, 0.73][row]
            left_x = [0.76, 0.72, 0.68, 0.32, 0.27][row]
            right_y = 0.60 if style < 2 else (0.43 if style == 2 else 0.52)
            left_y = 0.66 if style < 2 else 0.58
            def wrist(x, y):
                return [round(box[0] - x0 + (box[2] - box[0]) * x, 2), round(box[1] - y0 + (box[3] - box[1]) * y, 2)]
            result.append({"region": [x0, y0, x1 - x0, y1 - y0], "center": round(center - x0, 2), "feet": feet - y0, "pixel_size": round(scale, 8), "hand": wrist(right_x, right_y), "left_hand": wrist(left_x, left_y), "source_flip": (outfit == "dark_leaf" and row == 3 and style < 3) or (outfit == "base" and row == 3 and style == 2)})
    print(outfit, "20 poses; median height", round(HEIGHTS[outfit] / scale, 1), "px; scale", round(scale, 6))
    return result


if __name__ == "__main__":
    layout = {outfit: calibrate(outfit) for outfit in HEIGHTS}
    (ROOT / "layout.json").write_text(json.dumps(layout, indent=2) + "\n")
