#!/usr/bin/env python3
"""Rebuild the portable, articulated Fufu GLB. Uses only Python's standard library.

Run from any directory after placing material-atlas-smooth.png beside this source.
The atlas is generated art; geometry, UVs and animation are authored here.
"""
import json
import math
from pathlib import Path
import struct

HERE = Path(__file__).resolve().parent
PI = math.pi


def unit(v):
    length = math.sqrt(sum(x * x for x in v)) or 1
    return tuple(x / length for x in v)


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def add(a, b):
    return tuple(x+y for x, y in zip(a, b))


class Model:
    def __init__(self):
        self.binary = bytearray()
        self.doc = dict(asset={"version": "2.0", "generator": "Tofufu Adventure / authored Fufu 3D"},
                        scene=0, scenes=[{"nodes": [0]}], nodes=[], meshes=[],
                        materials=[], bufferViews=[], accessors=[], animations=[],
                        extensionsUsed=["KHR_materials_unlit"])
        self.root = self.node("Fufu3D")

    def blob(self, data, target=None):
        while len(self.binary) % 4:
            self.binary.append(0)
        view = {"buffer": 0, "byteOffset": len(self.binary), "byteLength": len(data)}
        if target:
            view["target"] = target
        self.binary.extend(data)
        self.doc["bufferViews"].append(view)
        return len(self.doc["bufferViews"])-1

    def accessor(self, rows, kind, integer=False):
        flat = [x for row in rows for x in row]
        data = struct.pack("<" + ("I" if integer else "f")*len(flat), *flat)
        value = dict(bufferView=self.blob(data), componentType=5125 if integer else 5126,
                     count=len(rows), type=kind)
        if kind in ("VEC3", "SCALAR"):
            value["min"] = [min(row[i] for row in rows) for i in range(len(rows[0]))]
            value["max"] = [max(row[i] for row in rows) for i in range(len(rows[0]))]
        self.doc["accessors"].append(value)
        return len(self.doc["accessors"])-1

    def node(self, name, parent=None, at=(0, 0, 0)):
        value = {"name": name, "translation": list(at)}
        self.doc["nodes"].append(value)
        index = len(self.doc["nodes"])-1
        if parent is not None:
            self.doc["nodes"][parent].setdefault("children", []).append(index)
        return index

    def material(self, name, tint, unlit=False, roughness=1):
        value = {"name": name, "pbrMetallicRoughness": {
            "baseColorFactor": list(tint), "baseColorTexture": {"index": 0},
            "metallicFactor": 0, "roughnessFactor": roughness}}
        if unlit:
            value["extensions"] = {"KHR_materials_unlit": {}}
        self.doc["materials"].append(value)
        return len(self.doc["materials"])-1

    def mesh(self, name, parent, parts, contour=0.0):
        primitives = []
        for geometry, material, quadrant in parts:
            vertices, normals, coords, indices = geometry
            u0, v0 = [(0, 0), (.5, 0), (0, .5), (.5, .5)][quadrant]
            uv = [(u0+.018+u*.464, v0+.018+v*.464) for u, v in coords]
            if "KHR_materials_unlit" in self.doc["materials"][material].get("extensions", {}):
                # Flat painted marks sample the quadrant centre. Polar UV seams must
                # not pull cream/gold mip colours into the small dark eyes or brows.
                uv = [(u0+.25, v0+.25)]*len(coords)
            primitives.append(dict(attributes={
                "POSITION": self.accessor(vertices, "VEC3"),
                "NORMAL": self.accessor(normals, "VEC3"),
                "TEXCOORD_0": self.accessor(uv, "VEC2")},
                indices=self.accessor([(i,) for i in indices], "SCALAR", True), material=material))
            if contour > 0:
                # The reversed, expanded shell shows only its ink silhouette.
                # It shares the part's animation pivot and travels in the GLB.
                shell = [add(p, tuple(n*contour for n in normal)) for p, normal in zip(vertices, normals)]
                reverse = [indices[i+j] for i in range(0, len(indices), 3) for j in (2, 1, 0)]
                primitives.append(dict(attributes={
                    "POSITION": self.accessor(shell, "VEC3"),
                    "NORMAL": self.accessor([tuple(-n for n in normal) for normal in normals], "VEC3"),
                    "TEXCOORD_0": self.accessor([(.75, .75)]*len(vertices), "VEC2")},
                    indices=self.accessor([(i,) for i in reverse], "SCALAR", True), material=INK))
        self.doc["meshes"].append({"name": name, "primitives": primitives})
        index = self.node(name, parent)
        self.doc["nodes"][index]["mesh"] = len(self.doc["meshes"])-1
        return index

    def animate(self, name, tracks, duration):
        times = [duration*i/32 for i in range(33)]
        time_accessor = self.accessor([(t,) for t in times], "SCALAR")
        animation = dict(name=name, samplers=[], channels=[])
        for node, path, function in tracks:
            rows = [function(t/duration*2*PI) for t in times]
            kind = "VEC4" if path == "rotation" else "VEC3"
            sampler = len(animation["samplers"])
            animation["samplers"].append(dict(input=time_accessor, output=self.accessor(rows, kind), interpolation="LINEAR"))
            animation["channels"].append(dict(sampler=sampler, target=dict(node=node, path=path)))
        self.doc["animations"].append(animation)

    def save(self):
        png = (HERE/"material-atlas-smooth.png").read_bytes()
        self.doc["images"] = [{"bufferView": self.blob(png), "mimeType": "image/png", "name": "Fufu painted surfaces"}]
        self.doc["samplers"] = [{"magFilter": 9729, "minFilter": 9987, "wrapS": 33071, "wrapT": 33071}]
        self.doc["textures"] = [{"source": 0, "sampler": 0}]
        self.doc["buffers"] = [{"byteLength": len(self.binary)}]
        data = json.dumps(self.doc, separators=(",", ":")).encode()
        data += b" " * (-len(data) % 4)
        binary = bytes(self.binary) + b"\0" * (-len(self.binary) % 4)
        glb = struct.pack("<III", 0x46546C67, 2, 28+len(data)+len(binary))
        glb += struct.pack("<II", len(data), 0x4E4F534A)+data
        glb += struct.pack("<II", len(binary), 0x004E4942)+binary
        (HERE/"fufu.glb").write_bytes(glb)
        triangles = sum(self.doc["accessors"][p["indices"]]["count"]//3
                        for m in self.doc["meshes"] for p in m["primitives"])
        print(f"Fufu: {triangles:,} triangles, {len(self.doc['meshes'])} meshes, {len(glb):,} bytes")


def parametric(function, rows=24, columns=40):
    vertices, normals, coords, indices = [], [], [], []
    epsilon = .0001
    for row in range(rows+1):
        v = row/rows
        for column in range(columns+1):
            u = column/columns
            point = function(u, v)
            du = tuple(b-a for a, b in zip(function(u-epsilon, v), function(u+epsilon, v)))
            dv = tuple(b-a for a, b in zip(function(u, v-epsilon), function(u, v+epsilon)))
            if sum(n*n for n in cross(du, dv)) < 1e-18:
                sample_v = max(epsilon, min(1-epsilon, v))
                du = tuple(b-a for a, b in zip(function(u-epsilon, sample_v), function(u+epsilon, sample_v)))
                dv = tuple(b-a for a, b in zip(function(u, sample_v-epsilon), function(u, sample_v+epsilon)))
            vertices.append(point)
            normals.append(unit(cross(du, dv)))
            coords.append((u, v))
    for row in range(rows):
        for column in range(columns):
            a = row*(columns+1)+column
            b = a+columns+1
            indices.extend((a, a+1, b, a+1, b+1, b))
    return vertices, normals, coords, indices


def merge(*geometries):
    result = ([], [], [], [])
    for vertices, normals, uv, indices in geometries:
        offset = len(result[0])
        result[0].extend(vertices)
        result[1].extend(normals)
        result[2].extend(uv)
        result[3].extend(i+offset for i in indices)
    return result


def ellipsoid(center, size, rows=16, columns=24):
    def point(u, v):
        a, b = 2*PI*u, PI*v
        return add(center, (size[0]*math.sin(b)*math.cos(a), size[1]*math.cos(b), size[2]*math.sin(b)*math.sin(a)))
    return parametric(point, rows, columns)


def bean_section(t):
    # Soft oval shoulders, full lower belly and a restrained inner bean curve.
    center = .035*t+.05*t*t-.01
    width = .575-.020*t+.014*math.cos(t*3)
    indentation = .027*math.exp(-((t-.12)/.34)**2)
    return center, width, indentation


def bean_point(u, v):
    angle, t = 2*PI*u, math.cos(PI*v)
    ring = abs(math.sin(PI*v))**.84
    center, width, indentation = bean_section(t)
    side = math.cos(angle)
    return (center+width*ring*side+indentation*max(0, -side)**4, .86+.70*t,
            .46*ring*math.sin(angle)*(1-.04*t))


def front(x, y, lift=0):
    # Fit every mark to the oval bean, including its curved, indented left flank.
    y = .86+(y-.89)*(.70/.72)-.14
    t = max(-.99, min(.99, (y-.86)/.70))
    ring = (1-t*t)**.42
    center, width, indentation = bean_section(t)
    x = center+x*1.04
    radius = width*ring
    side = (x-center)/radius
    for _ in range(5):
        negative = max(0, -side)
        side -= (radius*side+indentation*negative**4-(x-center))/(radius-4*indentation*negative**3)
    z = .46*ring*(1-.04*t)*math.sqrt(max(.01, 1-side*side))
    return (x, y, z+lift)


def face_patch(x, y, rx, ry, lift=.010, rings=5, segments=32):
    # Painted marks hug the skin; they must not look like raised beads or stickers.
    def point(u, v):
        angle, radius = 2*PI*u, v
        return front(x+rx*radius*math.cos(angle), y+ry*radius*math.sin(angle), lift+.001*(1-radius*radius))
    # Patch parameterization has opposite handedness to the body grid.
    vertices, normals, uv, indices = parametric(point, rings, segments)
    return vertices, [tuple(-x for x in n) for n in normals], uv, list(reversed(indices))


def tube(points, radius, sides=8):
    vertices, normals, uv, indices = [], [], [], []
    for i, point in enumerate(points):
        a, b = points[max(0, i-1)], points[min(len(points)-1, i+1)]
        tangent = unit(tuple(y-x for x, y in zip(a, b)))
        right = unit(cross(tangent, (0, 0, 1) if abs(tangent[2]) < .9 else (0, 1, 0)))
        up = cross(tangent, right)
        taper = .75 if i in (0, len(points)-1) else 1
        for j in range(sides+1):
            angle = j/sides*2*PI
            n = tuple(math.cos(angle)*r+math.sin(angle)*u for r, u in zip(right, up))
            vertices.append(add(point, tuple(x*radius*taper for x in n)))
            normals.append(n)
            uv.append((j/sides, i/max(1, len(points)-1)))
    for i in range(len(points)-1):
        for j in range(sides):
            a = i*(sides+1)+j
            b = a+sides+1
            indices.extend((a, a+1, b, a+1, b+1, b))
    return vertices, normals, uv, indices


def ink_curve(points):
    # A rounded painted ribbon follows the face without extruded tube shadows.
    vertices, normals, uv, indices = [], [], [], []
    width = .014
    for i, (x, y) in enumerate(points):
        a, b = points[max(0, i-1)], points[min(len(points)-1, i+1)]
        tangent = unit((b[0]-a[0], b[1]-a[1], 0))
        for side in (-1, 1):
            px, py = x-tangent[1]*width*side, y+tangent[0]*width*side
            vertices.append(front(px, py, .012))
            dx = tuple(b-a for a, b in zip(front(px-.0001, py), front(px+.0001, py)))
            dy = tuple(b-a for a, b in zip(front(px, py-.0001), front(px, py+.0001)))
            normals.append(unit(cross(dx, dy)))
            uv.append(((side+1)/2, i/(len(points)-1)))
        if i:
            a = (i-1)*2
            indices.extend((a, a+2, a+1, a+1, a+2, a+3))
    caps = [face_patch(x, y, width, width, .013, 1, 12) for x, y in (points[0], points[-1])]
    return merge((vertices, normals, uv, indices), *caps)


def path_point(points, progress):
    position = max(0, min(1, progress))*(len(points)-1)
    index = min(len(points)-2, int(position))
    t = position-index
    a, b = points[max(0, index-1)], points[index]
    c, d = points[index+1], points[min(len(points)-1, index+2)]
    return tuple(.5*(2*q+(-p+r)*t+(2*p-5*q+4*r-s)*t*t+
                      (-p+3*q-3*r+s)*t*t*t) for p, q, r, s in zip(a, b, c, d))


def soft_arm_point(side, u, v):
    # One continuous rounded loft joins the forearm and mitten, without a cuff seam.
    points = [(0, 0, 0), (side*.055, -.07, .085), (side*.06, -.17, .17),
              (-side*.02, -.24, .24), (-side*.14, -.245, .275),
              (-side*.20, -.235, .29), (-side*.245, -.23, .29)]
    center = path_point(points, v)
    tangent = unit(tuple(b-a for a, b in zip(path_point(points, v-.0001), path_point(points, v+.0001))))
    right = unit(cross(tangent, (0, 0, 1)))
    up = cross(tangent, right)
    cap = math.sqrt(max(0, 1-((v-.78)/.22)**2)) if v > .78 else 1
    radius = (.055+.030*min(1, max(0, v)/.12))*cap
    angle = 2*PI*u
    return add(center, tuple(radius*(math.cos(angle)*r+.80*math.sin(angle)*z) for r, z in zip(right, up)))


def leaf(start, end, width):
    direction = tuple(b-a for a, b in zip(start, end))
    side = unit((direction[1], -direction[0], 0))
    def point(u, v):
        w = max(0, math.sin(PI*v))**.82*width*math.cos(2*PI*u)
        # Closed lenticular volume, with curled tips and raised central rib.
        thickness = -.034*math.sin(PI*v)*math.sin(2*PI*u)
        return add(add(start, tuple(d*v for d in direction)),
                   (side[0]*w, side[1]*w, .03*math.sin(PI*v)+thickness))
    vertices, normals, uv, indices = parametric(point, 20, 16)
    uv = [(.5+.5*math.cos(2*PI*column/16), 1-row/20) for row in range(21) for column in range(17)]
    return vertices, normals, uv, indices


def rotation(axis, angle):
    return [axis[0]*math.sin(angle/2), axis[1]*math.sin(angle/2), axis[2]*math.sin(angle/2), math.cos(angle/2)]


model = Model()
SKIN = model.material("Smooth cream soybean", (1, 1, 1, 1), False, .68)
LEAF = model.material("Soft spring green sprout", (1, 1, 1, 1), False, .66)
GOLD = model.material("Painted golden freckles", (1, .97, .85, 1), True)
INK = model.material("Forest green ink", (1, 1, 1, 1), True)
EYE = model.material("Deep dark oval eyes", (.75, .82, .75, 1), True)
WHITE = model.material("Cream eye glints", (1, 1, 1, 1), True)
BLUSH = model.material("Soft peach blush", (1, .78, .69, 1), True)
CREASE = model.material("Soft hand creases", (.76, .70, .55, 1), True)
body = model.node("BodyPivot", model.root)
model.mesh("BeanBody", body, [(parametric(bean_point, 40, 64), SKIN, 0)], contour=.012)

# All marks conform to the body, rather than floating on a front-facing card.
eyes, glints, cheeks, freckles, strokes = [], [], [], [], []
for side in (-1, 1):
    x = side*.188
    eyes.append(face_patch(x, 1.135, .078, .108))
    glints.append(face_patch(x-.018, 1.176, .025, .030, .018))
    cheeks.append(face_patch(side*.312, .985, .071, .035, .012))
    points = [(x-.06+.12*i/16, 1.325+.026*math.sin(PI*i/16)) for i in range(17)]
    strokes.append(ink_curve(points))
strokes.append(ink_curve([(-.10+.2*i/24, .935-.04*math.sin(PI*i/24)) for i in range(25)]))
for x, y, radius in [(.274, 1.48, .026), (.351, 1.394, .021), (.38, 1.286, .023), (-.35, .68, .017)]:
    freckles.append(face_patch(x, y, radius, radius*1.1))
model.mesh("Eyes", body, [(merge(*eyes), EYE, 3)])
model.mesh("EyeGlints", body, [(merge(*glints), WHITE, 0)])
model.mesh("PeachCheeks", body, [(merge(*cheeks), BLUSH, 2)])
model.mesh("GoldenFreckles", body, [(merge(*freckles), GOLD, 2)])
model.mesh("BrowsAndSmile", body, [(merge(*strokes), INK, 3)])

shoulders, feet = [], []
for side, title in [(-1, "Right"), (1, "Left")]:
    shoulder = model.node(title+"Shoulder", body, (side*.48, .84, .15))
    shoulders.append(shoulder)
    arm = parametric(lambda u, v, side=side: soft_arm_point(side, u, v), 48, 20)
    model.mesh(title+"CurledHand", shoulder, [(arm, SKIN, 0)], contour=.009)
    fingers = []
    for i in range(3):
        fingers.append(tube([add(soft_arm_point(side, .71+.08*j/8, .83+i*.035), (0, 0, .002)) for j in range(9)], .0025, 6))
    model.mesh(title+"FingerInk", shoulder, [(merge(*fingers), CREASE, 0)])
    ankle = model.node(title+"FootPivot", model.root, (side*.205, .22, 0))
    feet.append(ankle)
    foot = ellipsoid((0, -.12, .045), (.14, .095, .16))
    leg = ellipsoid((0, -.025, -.01), (.076, .11, .078), 12, 16)
    model.mesh(title+"Foot", ankle, [(merge(foot, leg), SKIN, 0)], contour=.009)

sprout = model.node("SproutPivot", body, (bean_section(1)[0], 1.54, -.015))
stem = tube([(0, 0, 0), (-.005, .08, 0), (-.02, .16, 0), (-.04, .22, 0)], .028, 12)
model.mesh("SproutStem", sprout, [(stem, LEAF, 1)], contour=.0045)
left_leaf = leaf((-.025, .17, 0), (-.21, .40, .025), .082)
right_leaf = leaf((-.025, .17, 0), (.19, .29, .025), .092)
model.mesh("TwoSproutLeaves", sprout, [(merge(left_leaf, right_leaf), LEAF, 1)], contour=.005)

# Four small back freckles continue the original turnaround's soft golden spotting.
back_freckles = []
for x, y, r in [(-.24, 1.36, .025), (-.32, 1.26, .021), (.22, .52, .025), (.30, .60, .019)]:
    vertices, normals, uv, indices = face_patch(x, y, r, r)
    back_freckles.append(([(x, y, -z) for x, y, z in vertices],
                          [(x, y, -z) for x, y, z in normals], uv, list(reversed(indices))))
model.mesh("BackFreckles", body, [(merge(*back_freckles), GOLD, 2)])

walk_tracks = [
    (body, "translation", lambda p: (0, .018*(1-math.cos(p*2)), 0)),
    (body, "rotation", lambda p: rotation((0, 0, 1), .025*math.sin(p))),
    (sprout, "rotation", lambda p: rotation((0, 0, 1), .065*math.sin(p-.4))),
]
for index, shoulder in enumerate(shoulders):
    sign = -1 if index else 1
    walk_tracks.append((shoulder, "rotation", lambda p, s=sign: rotation((1, 0, 0), s*.08*math.sin(p))))
for index, foot in enumerate(feet):
    sign = -1 if index else 1
    x = -.205 if index == 0 else .205
    walk_tracks.append((foot, "translation", lambda p, s=sign, x=x: (x, .22+.07*max(0, s*math.sin(p)), .095*s*math.cos(p))))
    walk_tracks.append((foot, "rotation", lambda p, s=sign: rotation((1, 0, 0), -.12*max(0, s*math.sin(p)))))
model.animate("Walk", walk_tracks, 1.25)
model.animate("Idle", [(body, "translation", lambda p: (0, .006*math.sin(p), 0)),
                       (sprout, "rotation", lambda p: rotation((0, 0, 1), .035*math.sin(p)))], 3.0)
model.save()
