"""Generate the original factory prop blockout scenes from editable geometry data.

All measurements are Godot metres. These scenes are source geometry made for this
project, not converted third-party assets. Run from the repository root:
    python3 assets/factory/build_prop_scenes.py
"""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "game/world/factory/props"
OUT.mkdir(parents=True, exist_ok=True)

PALETTE = {
    "ink": "273b3b", "iron": "607976", "iron_light": "8fa6a0",
    "cream": "f0e9d2", "linen": "d1bf9b", "wood": "9b7656",
    "wood_dark": "684e3d", "brass": "c8a86b", "glass": "b8d4ca",
    "milk": "f8f2da", "green": "81a36d", "pod": "65805d",
    "bean": "d2bd89", "oil": "a3824e", "frost": "d5e9de",
    "red": "b5695a", "nori": "354e47", "steel": "bdc7bb",
}


class Scene:
    def __init__(self, title: str):
        self.title = title
        self.ext_resources: list[str] = []
        self.resources: list[str] = []
        self.nodes: list[str] = []
        self.count = 0
        self.node('node name="%s" type="Node3D"' % title)
        self.materials = {}
        self.textures = {}
        self.outline = ""

    def resource(self, kind: str, props: dict) -> str:
        self.count += 1
        rid = f"r{self.count}"
        lines = [f'[sub_resource type="{kind}" id="{rid}"]']
        lines += [f"{key} = {value}" for key, value in props.items()]
        self.resources.append("\n".join(lines))
        return rid

    def node(self, header: str, props: dict | None = None):
        lines = [f"[{header}]"]
        lines += [f"{key} = {value}" for key, value in (props or {}).items()]
        self.nodes.append("\n".join(lines))

    def mat(self, color: str, metallic: float = 0.0, roughness: float = 0.8, surface: str | None = None) -> str:
        surface = surface or ("iron" if color in ("iron", "iron_light", "brass", "steel", "ink") else "wood" if color in ("wood", "wood_dark") else "linen" if color == "linen" else "cream")
        key = (color, metallic, roughness, surface)
        if key not in self.materials:
            c = PALETTE.get(color, color)
            channels = [int(c[i:i+2], 16) / 255.0 for i in (0, 2, 4)]
            encoded = "Color(%s, %s, %s, 1.0)" % tuple(f"{channel:.6f}" for channel in channels)
            if surface not in self.textures:
                texture_id = f"e{len(self.ext_resources)+1}"
                self.ext_resources.append(f'[ext_resource type="Texture2D" path="res://assets/factory/surfaces/{surface}.svg" id="{texture_id}"]')
                self.textures[surface] = texture_id
            if not self.outline:
                self.outline = f"e{len(self.ext_resources)+1}"
                self.ext_resources.append(f'[ext_resource type="Material" path="res://game/world/factory/props/factory_ink.tres" id="{self.outline}"]')
            self.materials[key] = self.resource("StandardMaterial3D", {
                "albedo_color": encoded,
                "next_pass": f'ExtResource("{self.outline}")',
                "albedo_texture": f'ExtResource("{self.textures[surface]}")',
                "texture_filter": "5", "uv1_triplanar": "true",
                "uv1_scale": "Vector3(1, 1, 1)",
                "metadata/factory_surface": quote(surface),
                "metallic": str(metallic), "roughness": str(roughness),
                "diffuse_mode": "1", "specular_mode": "2",
            })
        return self.materials[key]

    def part(self, name: str, kind: str, pos, size, color: str, parent="StaticVisual", rot=None):
        if kind == "box":
            mesh = self.resource("BoxMesh", {"size": v(size)})
        elif kind == "sphere":
            mesh = self.resource("SphereMesh", {"radius": str(size[0]),
                                                 "height": str(size[1]), "radial_segments": "12", "rings": "6"})
        elif kind == "torus":
            mesh = self.resource("TorusMesh", {"inner_radius": str(size[0]),
                "outer_radius": str(size[1]), "rings": "16", "ring_segments": "8"})
        elif kind == "cylinder":
            mesh = self.resource("CylinderMesh", {"top_radius": str(size[0]),
                "bottom_radius": str(size[1]), "height": str(size[2]), "radial_segments": "12"})
        else:
            raise ValueError(kind)
        surface = "linen" if name == "FilledCanvas" else "grip" if name == "Belt" else None
        props = {"position": v(pos), "mesh": f'SubResource("{mesh}")',
                 "material_override": f'SubResource("{self.mat(color, surface=surface)}")'}
        if rot:
            props["rotation"] = v(rot)
        self.node(f'node name="{name}" type="MeshInstance3D" parent="{parent}"', props)

    def body(self, size, pos=(0, 0, 0)):
        self.node('node name="Body" type="StaticBody3D" parent="."',
                  {"collision_layer": "1", "collision_mask": "0"})
        shape = self.resource("BoxShape3D", {"size": v(size)})
        self.node('node name="Collision" type="CollisionShape3D" parent="Body"',
                  {"position": v(pos), "shape": f'SubResource("{shape}")'})
        self.node('node name="StaticVisual" type="Node3D" parent="."')
        self.node('node name="MovingParts" type="Node3D" parent="."')

    def socket(self, name: str, pos):
        self.node(f'node name="{name}" type="Marker3D" parent="."', {"position": v(pos)})

    def instance(self, name: str, filename: str, pos):
        rid = f"e{len(self.ext_resources) + 1}"
        self.ext_resources.append(
            f'[ext_resource type="PackedScene" path="res://game/world/factory/props/{filename}" id="{rid}"]')
        self.node(f'node name="{name}" parent="." instance=ExtResource("{rid}")',
                  {"position": v(pos)})

    def label(self, name: str, text: str, pos, pixel=0.004, billboard=False):
        # Signs are backed by their own plates. Labels are for inspection views.
        self.node(f'node name="{name}" type="Label3D" parent="."', {
            "double_sided": "false",
            "position": v(pos), "text": quote(text), "font_size": "32",
            "pixel_size": str(pixel), "billboard": "1" if billboard else "0", "no_depth_test": "false",
            "modulate": "Color(0.152941, 0.231373, 0.231373, 1.0)",
        })

    def save(self, filename: str):
        payload = "[gd_scene load_steps=%d format=3]\n\n" % (
            len(self.resources) + len(self.ext_resources) + 1)
        payload += "\n\n".join(self.ext_resources + self.resources + self.nodes) + "\n"
        (OUT / filename).write_text(payload)


def v(coords):
    return "Vector3(%s)" % ", ".join(str(round(float(x), 5)) for x in coords)


def quote(value: str):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def ports(s: Scene, input_pos, output_pos, interaction_pos, fluid=False):
    s.socket("input", input_pos)
    s.socket("output", output_pos)
    s.socket("interaction", interaction_pos)
    s.socket("service_access", (-1.2, 0.7, 0))
    if fluid:
        s.socket("fluid_in", input_pos)
        s.socket("fluid_out", output_pos)


def sack(name, tone, motif, contents):
    s = Scene(name)
    s.body((0.62, 0.68, 0.48), (0, 0.36, 0))
    radius, height = {"pod": (0.38, 0.62), "round": (0.3, 0.82), "oil": (0.4, 0.56)}[motif]
    s.part("FilledCanvas", "sphere", (0, 0.36, 0), (radius, height), tone)
    s.part("FoldedNeck", "cylinder", (0, 0.7, 0), (0.17, 0.24, 0.18), "linen")
    tag_z = radius + 0.015
    s.part("HarvestTag", "box", (0, 0.42, tag_z), (0.36, 0.23, 0.025), "cream")
    s.part("StitchLeft", "box", (-0.28, 0.35, 0.19), (0.025, 0.36, 0.025), "wood_dark")
    s.part("StitchRight", "box", (0.28, 0.35, 0.19), (0.025, 0.36, 0.025), "wood_dark")
    if motif == "pod":
        for i in range(3):
            s.part(f"Pod{i+1}", "sphere", (-0.15 + 0.15*i, 0.84, 0.02), (0.1, 0.17), "pod")
    elif motif == "round":
        for i in range(5):
            s.part(f"Bean{i+1}", "sphere", (-0.18 + 0.09*i, 0.82, 0.06), (0.06, 0.12), "bean")
    else:
        for i in range(3):
            s.part(f"OilSeed{i+1}", "sphere", (-0.15 + 0.15*i, 0.82, 0.02), (0.09, 0.16), "oil")
        s.part("OilStain", "sphere", (0.16, 0.31, 0.28), (0.1, 0.08), "oil")
    s.label("TagText", contents.replace(" / ", "\n").replace(" ", "\n"), (0, 0.43, tag_z + 0.045), 0.0017)
    s.socket("carry_grip", (0, 0.75, 0))
    s.socket("interaction", (0, 0.5, 0.48))
    s.socket("input", (0, 0, 0))
    s.socket("output", (0, 0, 0))
    s.save(name.lower() + ".tscn")


def intake(name, title, kind):
    s = Scene(name)
    s.body((2.0, 1.4, 1.4), (0, 0.72, 0))
    s.part("Housing", "box", (0, 0.7, 0), (2.0, 1.4, 1.4), "iron")
    for x in (-0.77, 0.77):
        s.part(f"Foot{'L' if x < 0 else 'R'}", "box", (x, 0.1, 0), (0.28, 0.2, 1.5), "ink")
    s.part("IntakeLip", "box", (0, 1.45, 0.25), (1.45, 0.12, 0.95), "brass")
    s.part("InputWell", "box", (0, 1.48, 0.1), (1.25, 0.03, 0.75), "ink")
    s.part("InspectionPlate", "box", (0, 0.85, 0.72), (1.55, 0.46, 0.06), "cream")
    if kind == "chilled":
        for i in range(4):
            s.part(f"VentFin{i+1}", "box", (-0.7 + i*0.46, 0.45, 0.74), (0.16, 0.28, 0.04), "frost")
        s.part("Compressor", "cylinder", (-0.6, 0.95, -0.84), (0.35, 0.35, 0.65), "ink", rot=(1.57, 0, 0))
        s.part("InsulatedDoor", "box", (1.06, 0.88, 0), (0.14, 1.36, 1.18), "frost")
    elif kind == "mill":
        s.part("GrindingDrum", "cylinder", (-0.54, 1.0, -0.84), (0.36, 0.36, 0.68), "wood", rot=(1.57, 0, 0))
        s.part("FilterCloth", "box", (0.48, 1.32, -0.61), (0.67, 0.07, 0.6), "linen")
        s.part("MilkPipe", "cylinder", (1.03, 0.52, -0.4), (0.08, 0.08, 0.9), "steel", rot=(1.57, 0, 0))
    else:
        for x in (-0.35, 0.35):
            s.part(f"Roller{int(x*100)}", "cylinder", (x, 1.13, -0.82), (0.25, 0.25, 0.65), "brass", rot=(1.57, 0, 0))
        s.part("OilGauge", "cylinder", (0.64, 0.86, 0.78), (0.18, 0.18, 0.06), "cream", rot=(1.57, 0, 0))
        s.part("CandleMould", "cylinder", (1.2, 0.35, 0.18), (0.13, 0.13, 0.55), "milk")
    s.label("LinePlate", title, (0, 0.86, 0.785), 0.0025)
    caption = {"chilled": "CHILLED INTAKE", "mill": "TOFU MILL", "oil": "OIL MILL"}[kind]
    s.label("LineCaption", caption, (0, 2.05, 0), 0.004)
    ports(s, (0, 1.55, 0.3), (0, 0.65, -0.8), (0, 0.8, 1.4), kind == "mill")
    s.save(name.lower() + ".tscn")


CHEMICALS = [
    "Nigari", "Gypsum", "Citric acid", "Vinegar", "Lemon concentrate",
    "Glucono-delta-lactone", "Calcium chloride", "Table salt", "Baking soda",
    "Sodium carbonate", "Sugar", "Starch", "Agar", "Gelatin", "Yeast",
    "Pectin", "Potassium citrate", "Sodium citrate", "Distilled water", "Mineral oil",
]


def bottle(index: int, content: str):
    s = Scene("Bottle%02d" % index)
    s.nodes[0] += "\nmetadata/content_id = %s" % quote(content.lower().replace(" ", "_").replace("-", "_"))
    s.body((0.2, 0.4, 0.2), (0, 0.2, 0))
    s.part("Vessel", "cylinder" if index % 3 else "box", (0, 0.2, 0),
           (0.1, 0.1, 0.34) if index % 3 else (0.2, 0.34, 0.2), "glass")
    s.part("Contents", "cylinder", (0, 0.12, 0), (0.075, 0.075, 0.16),
           ("milk", "bean", "green", "oil")[index % 4])
    s.part("Cap", "cylinder", (0, 0.38, 0), (0.12, 0.12, 0.09),
           ("wood_dark", "ink", "brass")[index % 3])
    s.part("PaperLabel", "box", (0, 0.23, 0.105), (0.18, 0.11, 0.012), "cream")
    s.label("ContentLabel", content, (0, 0.235, 0.142), 0.0007)
    s.socket("carry_grip", (0, 0.42, 0))
    s.socket("interaction", (0, 0.24, 0.35))
    s.save("bottle_%02d.tscn" % index)


def rack():
    s = Scene("LabRack")
    s.body((4.5, 1.85, 0.5), (0, 0.925, 0))
    for x in (-2.15, 0, 2.15):
        s.part(f"Post{int(x*100)}", "box", (x, 0.94, 0), (0.11, 1.88, 0.54), "iron")
    for y in (0.08, 0.92, 1.76):
        s.part(f"Shelf{int(y*100)}", "box", (0, y, 0), (4.5, 0.1, 0.55), "wood")
    for i, content in enumerate(CHEMICALS):
        x, y = -1.92 + (i % 10) * 0.425, 0.12 if i < 10 else 0.96
        # Individually named placement sockets carry fixed content IDs.
        s.socket("content_%02d_%s" % (i, content.lower().replace(" ", "_").replace("-", "_")), (x, y, 0.04))
        s.instance("Bottle%02d" % i, "bottle_%02d.tscn" % i, (x, y, 0.04))
    s.socket("interaction", (0, 0.9, 0.75))
    s.save("lab_rack.tscn")


def traditional_press():
    s = Scene("TraditionalPress")
    s.body((2.0, 1.8, 1.8), (0, 0.9, 0))
    for x in (-0.85, 0.85):
        for z in (-0.75, 0.75):
            s.part(f"Post_{x}_{z}", "box", (x, 0.94, z), (0.16, 1.88, 0.16), "wood_dark")
    s.part("Vessel", "box", (0, 0.58, 0), (1.64, 0.3, 1.42), "wood")
    s.part("CurdCloth", "box", (0, 0.77, 0), (1.43, 0.08, 1.22), "linen")
    s.part("CompressionPlate", "box", (0, 1.05, 0), (1.37, 0.16, 1.16), "wood", "MovingParts")
    s.part("WheyChannel", "box", (0, 0.2, 1.05), (1.25, 0.08, 0.5), "brass")
    s.part("CraftCard", "box", (0, 2.23, -0.85), (1.8, 0.55, 0.06), "cream")
    s.label("CraftCardText", "SOFT: 1 STONE / 3 s\nFIRM: 2 STONES / 5 s\nLIFT TO RELEASE", (0, 2.23, -0.785), 0.004)
    ports(s, (0, 0.85, 1.2), (0, 0.2, 1.3), (0, 0.8, 1.65), True)
    for i, x in enumerate((-0.42, 0, 0.42)):
        s.socket("stone_socket_%d" % (i+1), (x, 1.15, 0))
    s.save("traditional_press.tscn")


def stone():
    s = Scene("PressStone")
    s.body((0.42, 0.2, 0.38), (0, 0.1, 0))
    s.part("Weight", "sphere", (0, 0.12, 0), (0.23, 0.2), "iron_light")
    s.part("Grip", "box", (0, 0.24, 0), (0.2, 0.06, 0.15), "ink")
    s.socket("carry_grip", (0, 0.3, 0))
    s.socket("interaction", (0, 0.2, 0.4))
    s.save("press_stone.tscn")


def modern_press():
    s = Scene("ModernPress")
    s.body((2.0, 2.3, 1.7), (0, 1.15, 0))
    s.part("Frame", "box", (0, 1.14, 0), (2, 2.28, 1.7), "iron")
    s.part("OpenBay", "box", (0, 1.13, 0.87), (1.56, 0.95, 0.05), "ink")
    s.part("LowerPlate", "box", (0, 0.7, 0.6), (1.48, 0.13, 1.05), "steel")
    s.part("MovingPlate", "box", (0, 1.47, 0.59), (1.48, 0.15, 1.05), "steel", "MovingParts")
    s.part("GaugeFace", "cylinder", (0, 1.95, 0.9), (0.32, 0.32, 0.08), "cream", rot=(1.57, 0, 0))
    s.part("GaugeNeedle", "box", (0, 1.98, 0.96), (0.03, 0.22, 0.03), "red", "MovingParts")
    s.part("CalibrationPlate", "box", (0, 1.95, 0.95), (0.45, 0.18, 0.025), "brass")
    s.label("BandText", "82 - 90", (0, 1.95, 0.995), 0.002)
    for side, x in (("Start", -1.1), ("Stop", 1.1)):
        s.part(side+"Lever", "cylinder", (x, 1.03, 0.46), (0.045, 0.045, 0.52), "brass", "MovingParts", (0, 0, 0.3))
        s.part(side+"Knob", "sphere", (x, 1.32, 0.46), (0.1, 0.17), "red" if side == "Stop" else "green", "MovingParts")
    ports(s, (0, 0.8, 1.25), (0, 0.8, -0.95), (0, 1.0, 1.6))
    s.save("modern_press.tscn")


def cutter():
    s = Scene("Cutter")
    s.body((4.8, 1.25, 1.65), (0, 0.625, 0))
    s.part("Carriage", "box", (0, 0.64, 0), (4.8, 1.28, 1.65), "iron")
    s.part("Track", "box", (0, 1.3, 0), (4.35, 0.1, 1.38), "wood")
    s.part("QuestBlock", "box", (0, 1.48, 0), (3.6, 0.28, 1.15), "milk", "MovingParts")
    for i in range(5):
        x = -1.5 + i*0.75
        s.part(f"Guide{i+1}", "box", (x, 1.76, 0), (0.05, 0.26, 1.3), "brass", "MovingParts")
        s.socket(f"guide_{i+1}", (x, 1.83, 0.7))
    s.part("Blade", "box", (0, 2.12, 0), (0.05, 0.36, 1.4), "steel", "MovingParts")
    s.part("Ruler", "box", (0, 1.35, 0.74), (4.0, 0.025, 0.06), "cream")
    ports(s, (-2.4, 1.5, 0), (2.4, 1.5, 0), (0, 1.2, 1.6))
    s.save("cutter.tscn")


def packer():
    s = Scene("Packer")
    s.body((5.8, 1.1, 1.65), (0, 0.55, 0))
    s.part("Conveyor", "box", (0, 0.58, 0), (5.8, 1.16, 1.65), "iron")
    s.part("Belt", "box", (0, 1.19, 0), (5.48, 0.06, 1.39), "wood_dark")
    for i in range(6):
        x = -2.25 + i*0.9
        s.part(f"Dock{i+1}", "box", (x, 1.24, 0), (0.78, 0.05, 1.0), "cream")
        s.part(f"Film{i+1}", "box", (x, 1.45, 0), (0.74, 0.02, 0.94), "glass", "MovingParts")
        s.socket(f"slot_{i+1}", (x, 1.3, 0))
    s.part("FilmRoll", "cylinder", (0, 1.78, -0.76), (0.15, 0.15, 5.0), "linen", "MovingParts", (0, 0, 1.57))
    ports(s, (-3.0, 1.3, 0), (3.0, 1.3, 0), (0, 1.1, 1.7))
    s.save("packer.tscn")


def equipment():
    s = Scene("DofufuKatana")
    s.body((0.12, 1.2, 0.12), (0, 0.6, 0))
    s.part("Blade", "box", (0, 0.84, 0), (0.07, 0.72, 0.035), "steel")
    s.part("Edge", "box", (0.045, 0.84, 0), (0.015, 0.72, 0.025), "cream")
    s.part("Guard", "box", (0, 0.45, 0), (0.3, 0.05, 0.12), "brass")
    s.part("Grip", "cylinder", (0, 0.23, 0), (0.045, 0.045, 0.42), "nori")
    s.socket("carry_grip", (0, 0.22, 0))
    s.socket("interaction", (0, 0.5, 0.2))
    s.save("dofufu_katana.tscn")
    s = Scene("DofufuNoriSet")
    s.body((0.5, 0.66, 0.2), (0, 0.34, 0))
    s.part("ChestWrap", "box", (0, 0.38, 0), (0.5, 0.62, 0.19), "nori")
    s.part("WaistSash", "box", (0, 0.16, 0.11), (0.54, 0.13, 0.08), "brass")
    for x in (-0.32, 0.32):
        s.part(f"Shoulder{x}", "sphere", (x, 0.58, 0), (0.18, 0.22), "nori")
    s.socket("carry_grip", (0, 0.36, 0))
    s.socket("interaction", (0, 0.36, 0.3))
    s.save("dofufu_nori_set.tscn")


def milk_line():
    s = Scene("ConnectedMilkLine")
    s.body((5.5, 0.45, 0.45), (0, 1.95, 0))
    s.part("OverheadPipe", "cylinder", (0, 1.95, 0), (0.14, 0.14, 5.5), "steel", rot=(0, 0, 1.57))
    for x in (-2.15, -0.8, 0.8, 2.15):
        s.part(f"Joint{x}", "cylinder", (x, 1.95, 0), (0.19, 0.19, 0.13), "brass", rot=(0, 0, 1.57))
    s.part("SightGlass", "cylinder", (0, 1.95, 0), (0.16, 0.16, 0.9), "glass", rot=(0, 0, 1.57))
    s.part("MilkCore", "cylinder", (0, 1.95, 0), (0.09, 0.09, 0.89), "milk", "MovingParts", (0, 0, 1.57))
    s.part("PumpHousing", "box", (-1.45, 0.6, 0), (0.8, 1.2, 0.75), "iron")
    s.part("PumpDial", "cylinder", (-1.45, 0.92, 0.39), (0.21, 0.21, 0.08), "cream", rot=(1.57, 0, 0))
    s.part("DripTray", "box", (0, 0.16, 0), (1.0, 0.1, 0.55), "brass")
    s.socket("fluid_in", (-2.75, 1.95, 0))
    s.socket("fluid_out", (2.75, 1.95, 0))
    s.socket("input", (-2.75, 1.95, 0))
    s.socket("output", (2.75, 1.95, 0))
    s.socket("interaction", (0, 1.2, 0.65))
    s.socket("service_access", (-1.45, 0.8, 0.75))
    s.save("connected_milk_line.tscn")


def lab_support():
    s = Scene("CoagulationTank")
    s.body((2.3, 1.55, 2.2), (0, 0.775, 0))
    s.part("Tank", "cylinder", (0, 0.81, 0), (1.05, 1.05, 1.4), "iron")
    s.part("MilkLevel", "cylinder", (0, 1.59, 0), (0.91, 0.91, 0.025), "milk", "MovingParts")
    s.part("Rim", "torus", (0, 1.64, 0), (1.0, 1.1), "brass")
    s.part("Spout", "cylinder", (1.15, 1.55, 0), (0.09, 0.09, 0.5), "steel", rot=(0, 0, 1.57))
    s.part("SightGlass", "box", (0, 0.96, 1.04), (0.28, 0.8, 0.05), "glass")
    s.part("CurdPreview", "sphere", (0, 1.68, 0), (0.46, 0.14), "cream", "MovingParts")
    ports(s, (-1.2, 1.55, 0), (1.42, 1.55, 0), (0, 0.9, 1.5), True)
    s.save("coagulation_tank.tscn")
    s = Scene("LabTerminal")
    s.body((0.95, 1.55, 0.62), (0, 0.775, 0))
    s.part("Pedestal", "box", (0, 0.75, 0), (0.75, 1.5, 0.58), "iron")
    s.part("ScreenFrame", "box", (0, 1.21, 0.36), (0.9, 0.55, 0.1), "ink")
    s.part("ScreenSurface", "box", (0, 1.21, 0.42), (0.78, 0.43, 0.01), "glass")
    s.part("KeyboardDeck", "box", (0, 0.75, 0.48), (0.72, 0.08, 0.34), "wood")
    s.socket("interaction", (0, 1.1, 0.9))
    s.socket("service_access", (0, 0.8, -0.55))
    s.save("lab_terminal.tscn")
    s = Scene("ShiftNote")
    s.body((0.27, 0.05, 0.19), (0, 0.025, 0))
    s.part("FoldedPaper", "box", (0, 0.04, 0), (0.26, 0.018, 0.18), "cream")
    s.part("Fold", "box", (0, 0.052, 0), (0.015, 0.007, 0.18), "linen")
    s.part("OperatorMark", "box", (-0.065, 0.053, -0.03), (0.07, 0.003, 0.007), "ink")
    s.socket("interaction", (0, 0.1, 0.35))
    s.save("shift_note.tscn")


if __name__ == "__main__":
    (OUT / "factory_ink.tres").write_text('[gd_resource type="ShaderMaterial" load_steps=2 format=3]\n\n[ext_resource type="Shader" path="res://game/world/common/ink_outline.gdshader" id="1"]\n\n[resource]\nshader = ExtResource("1")\nshader_parameter/width = 0.008\n')
    sack("EdamameSack", "green", "pod", "FRESH PODS")
    sack("MatureSack", "linen", "round", "DRY / PROTEIN")
    sack("HighFatSack", "wood", "oil", "HIGH OIL")
    intake("ChilledIntake", "CHILLED / PODS", "chilled")
    intake("TofuMill", "SOAK / GRIND / FILTER", "mill")
    intake("OilIntake", "OIL / WAX", "oil")
    for i, chemical in enumerate(CHEMICALS):
        bottle(i, chemical)
    rack()
    traditional_press()
    stone()
    modern_press()
    cutter()
    packer()
    equipment()
    milk_line()
    lab_support()
    print("Generated", len(list(OUT.glob("*.tscn"))), "factory prop scenes in", OUT)
