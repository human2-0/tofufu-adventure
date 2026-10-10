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

# Seamless vector paint, scaled in metres by FactorySurfaceMaterials. Broad
# marks survive the overhead camera; fine weave/grain rewards close inspection.
BRUSHES = '''
<path d="M-20 34 C42 17 110 55 274 29" stroke="#fff" stroke-opacity=".14" stroke-width="19"/>
<path d="M-10 86 C55 103 112 72 265 92" stroke="#756f66" stroke-opacity=".12" stroke-width="11"/>
<path d="M-10 165 C39 140 158 177 275 151" stroke="#fff" stroke-opacity=".10" stroke-width="27"/>
<path d="M-10 219 C73 201 141 233 273 211" stroke="#706b63" stroke-opacity=".10" stroke-width="15"/>
'''
for kind in ("iron", "wood", "linen", "cream", "floor", "plaster", "roof", "grip"):
    details, brush, base = "", BRUSHES, "#e4e1d7"
    if kind == "wood":
        base = "#e6dfcc"
        details = ''.join(f'<path d="M-8 {y} C60 {y-7} 105 {y+8} 270 {y-3}" stroke="#827464" stroke-opacity=".26" stroke-width="2"/>' for y in range(8, 256, 18))
        details += '<path d="M0 0 V256 M128 0 V256 M256 0 V256" stroke="#776958" stroke-opacity=".20" stroke-width="3"/>'
        details += '<ellipse cx="72" cy="113" rx="22" ry="6" stroke="#756e62" stroke-opacity=".35" stroke-width="2"/>'
    elif kind == "linen":
        base = "#e5dfca"
        details = ''.join(f'<path d="M0 {y} H256 M{y} 0 V256" stroke="#857f72" stroke-opacity=".20" stroke-width="2"/>' for y in range(4, 256, 8))
        details += '<path d="M0 16 H256 M16 0 V256" stroke="#fff" stroke-opacity=".2" stroke-width="2"/>'
    elif kind == "iron":
        details = ''.join(f'<path d="M0 {y} H256" stroke="#738783" stroke-opacity=".10" stroke-width="1"/>' for y in range(5, 256, 11))
        details += '<path d="M25 0 L17 56 M143 135 L181 124 M219 28 L232 61 M31 197 L57 189" stroke="#fff" stroke-opacity=".40" stroke-width="3"/>'
        details += '<path d="M25 3 L20 53 M145 137 L179 126" stroke="#64716d" stroke-opacity=".2" stroke-width="2"/>'
    elif kind == "floor":
        brush = ""
        details = '<rect x="4" y="4" width="120" height="120" fill="#efede2"/><rect x="132" y="132" width="120" height="120" fill="#ece9df"/>'
        details += '<path d="M0 0 H256 M0 128 H256 M0 256 H256 M0 0 V256 M128 0 V256 M256 0 V256" stroke="#8e9991" stroke-width="5"/>'
        details += '<path d="M5 9 H118 M137 137 H248" stroke="#fff" stroke-opacity=".60" stroke-width="3"/>'
        details += '<path d="M29 88 Q46 91 63 85 M185 39 L219 29 M164 212 Q181 223 215 216" stroke="#aaa99d" stroke-opacity=".38" stroke-width="3"/>'
    elif kind == "plaster":
        base = "#e5e3d7"
        details = '<path d="M0 126 H256" stroke="#8b9690" stroke-opacity=".32" stroke-width="3"/>'
        details += '<path d="M34 71 L44 83 L39 89 M189 181 L177 192" stroke="#b1b6a8" stroke-width="3"/>'
        details += ''.join(f'<circle cx="{(i*53)%256}" cy="{(i*97)%256}" r="{2+i%3}" fill="#a8afa2" opacity=".14"/>' for i in range(24))
    elif kind == "roof":
        brush = ""
        details = ''.join(f'<rect x="{x}" width="9" height="256" fill="#a0b0a9"/><rect x="{x+10}" width="7" height="256" fill="#f4f0df"/>' for x in range(0, 256, 32))
        details += '<path d="M0 16 H256 M0 240 H256" stroke="#899d94" stroke-opacity=".4" stroke-width="2"/>'
    elif kind == "grip":
        brush = ""
        details = ''.join(f'<path d="M{x} {y} l8 -8 M{x+16} {y} l8 8" stroke="#919e93" stroke-width="4"/>' for y in range(16, 256, 32) for x in range(0, 256, 32))
        details += '<path d="M0 1 H256 M0 255 H256" stroke="#acb4a7" stroke-width="2"/>'
    else:
        details = '<path d="M20 11 Q60 27 87 13 M153 110 Q184 95 225 109 M28 182 Q48 189 81 179" stroke="#fff" stroke-opacity=".20" stroke-width="9"/>'
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 256 256">
<rect width="256" height="256" fill="{base}"/>
<g fill="none" stroke-linecap="round">{brush}{details}</g>
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
print("Generated eight original surface textures and six original machine sounds")
