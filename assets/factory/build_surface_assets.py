"""Original editable factory surface strokes and synthesized machine sound sources.
No third-party textures, samples or model data are used. Run from project root.
"""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parent
SURFACES = ROOT / "surfaces"
SOUNDS = ROOT / "sounds"
SURFACES.mkdir(exist_ok=True)
SOUNDS.mkdir(exist_ok=True)

# Fixed brush paths are authored as vector source, preserving editable paint marks.
BRUSHES = '''
<path d="M-20 34 C42 17 110 55 274 29" stroke="#fff" stroke-opacity=".09" stroke-width="19"/>
<path d="M-10 86 C55 103 112 72 265 92" stroke="#726c60" stroke-opacity=".06" stroke-width="11"/>
<path d="M-10 165 C39 140 158 177 275 151" stroke="#fff" stroke-opacity=".08" stroke-width="27"/>
<path d="M-10 219 C73 201 141 233 273 211" stroke="#706b63" stroke-opacity=".055" stroke-width="15"/>
'''
for kind in ("iron", "wood", "linen", "cream"):
    details = ""
    if kind == "wood":
        details = ''.join(f'<path d="M-8 {y} C60 {y-12} 105 {y+13} 270 {y-3}" stroke="#756e62" stroke-opacity=".13" stroke-width="2"/>' for y in range(8, 256, 23))
        details += '<ellipse cx="72" cy="113" rx="20" ry="5" stroke="#756e62" stroke-opacity=".13" stroke-width="2"/>'
    elif kind == "linen":
        details = ''.join(f'<path d="M0 {y} H256 M{y} 0 V256" stroke="#746f64" stroke-opacity=".06" stroke-width="1"/>' for y in range(4, 256, 8))
    elif kind == "iron":
        details = '<path d="M25 0 L17 56 M143 135 L181 124 M219 28 L232 61 M31 197 L57 189" stroke="#fff" stroke-opacity=".14" stroke-width="2"/>'
    else:
        details = '<path d="M20 11 Q60 27 87 13 M153 110 Q184 95 225 109 M28 182 Q48 189 81 179" stroke="#fff" stroke-opacity=".07" stroke-width="9"/>'
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 256 256">
<rect width="256" height="256" fill="#e8e5dd"/>
<g fill="none" stroke-linecap="round">{BRUSHES}{details}</g>
</svg>'''
    (SURFACES / f"{kind}.svg").write_text(svg)

RATE = 22050
for name, duration in {"mill": 1.0, "pressure": 1.0, "pour": 0.8, "flush": 1.0, "blade": 0.5, "seal": 0.6}.items():
    noise = random.Random(8142)
    data = bytearray()
    for index in range(int(RATE * duration)):
        t = index / RATE
        phase = t / duration
        edge = min(1.0, t / .04, (duration-t) / .07)
        jitter = noise.uniform(-1, 1)
        if name == "mill":
            value = .16 * math.sin(2*math.pi*90*t) + .06*math.sin(2*math.pi*180*t) + .025*jitter
        elif name == "pressure":
            value = .10 * math.sin(2*math.pi*62*t) + .04*math.sin(2*math.pi*124*t) + .015*jitter
        elif name in ("pour", "flush"):
            value = .12*jitter + .045*math.sin(2*math.pi*(260+40*math.sin(phase*12))*t)
        elif name == "blade":
            value = (.17*jitter + .10*math.sin(2*math.pi*130*t))*math.exp(-phase*5)
        else:
            value = (.07*jitter + .10*math.sin(2*math.pi*310*t)) * math.sin(math.pi*phase)
        data += struct.pack('<h', int(max(-1, min(1, value*edge))*32767))
    with wave.open(str(SOUNDS / f"{name}.wav"), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(data)
print("Generated four original surface textures and six original machine sounds")
