"""Extract labeled source-sheet frames into foot-aligned runtime atlases (Pillow)."""
from pathlib import Path
from PIL import Image, ImageFilter, ImageChops

ROOT = Path(__file__).resolve().parents[1] / "assets/characters/snail"


def silhouettes(source):
    alpha = source.getchannel("A")
    pending = {(x, y) for y in range(source.height) for x in range(source.width)
               if alpha.getpixel((x, y)) > 200}
    frames = []
    while pending:
        seed = pending.pop()
        island, stack = {seed}, [seed]
        while stack:
            x, y = stack.pop()
            for neighbor in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
                if neighbor in pending:
                    pending.remove(neighbor)
                    island.add(neighbor)
                    stack.append(neighbor)
        if len(island) < 8000:
            continue
        mask = Image.new("L", source.size)
        for point in island:
            mask.putpixel(point, 255)
        mask = mask.filter(ImageFilter.MaxFilter(3))
        frame = source.copy()
        frame.putalpha(ImageChops.multiply(alpha, mask))
        box = frame.getbbox()
        frames.append((box, frame.crop(box)))
    return frames


for name in ("idle", "walking", "attack"):
    source = Image.open(ROOT / "source" / f"{name}_snail.png").convert("RGBA")
    frames = silhouettes(source)
    assert len(frames) == 25, (name, len(frames))
    frames.sort(key=lambda item: (item[0][1] + item[0][3]) / 2)
    atlas = Image.new("RGBA", (1280, 1280))
    for row in range(5):
        ordered = sorted(frames[row*5:row*5+5], key=lambda item: item[0][0])
        for column, (_, frame) in enumerate(ordered):
            assert frame.width <= 256 and frame.height <= 240
            atlas.paste(frame, (column*256 + (256-frame.width)//2,
                                row*256 + 240-frame.height))
    atlas.save(ROOT / f"{name}.png")
