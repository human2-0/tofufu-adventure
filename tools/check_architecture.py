#!/usr/bin/env python3
"""Small source-level guardrails, not a replacement for Godot's parser."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    errors = []
    scripts = sorted((ROOT / "game").rglob("*.gd"))
    classes = {}
    for path in scripts:
        match = re.search(r"^class_name\s+(\w+)", path.read_text(), re.M)
        if match:
            name = match[1]
            if name in classes:
                errors.append(f"Duplicate class: {name}")
            classes[name] = path

    for path in scripts:
        relative = path.relative_to(ROOT)
        text = path.read_text()
        # Ignore comments and strings when checking type-level dependencies.
        code = re.sub(r'"[^"\n]*"|#[^\n]*', '', text)
        feature = relative.parts[1]
        if feature != "app":
            for name, target in classes.items():
                if target.relative_to(ROOT).parts[1] != feature and re.search(rf"\b{name}\b", code):
                    errors.append(f"{relative}: cross-feature dependency on {name}; inject a narrow contract")
        if re.search(r"\bHolepunchTransport\b", code) or "res://networking/sidecar/" in text:
            errors.append(f"{relative}: concrete backend belongs in scene composition or networking adapters")
        if re.search(r"\b(get_first_node_in_group|find_child|find_children)\s*\(", code):
            errors.append(f"{relative}: hidden scene lookup")
        if feature != "app" and re.search(r"\b(ENetMultiplayerPeer|WebSocketPeer|TCPServer|StreamPeerTCP|HTTPRequest)\b", code):
            errors.append(f"{relative}: transport belongs in networking adapters")
        if path.name == "player_motor.gd" and re.search(r"\b(Input|Node|Node3D|CharacterBody3D|Sprite3D|FileAccess|get_tree|get_node|load|preload)\b", code):
            errors.append(f"{relative}: movement rules depend on an external system")
        if len(text.splitlines()) > 200:
            print(f"REVIEW: {relative} exceeds 200 lines; consider responsibility boundaries")

    sources = [ROOT / "project.godot"]
    sources += list((ROOT / "game").rglob("*.gd"))
    sources += list((ROOT / "game").rglob("*.tscn"))
    sources += list((ROOT / "game").rglob("*.tres"))
    for path in sources:
        for resource in re.findall(r'res://([^"\s)]+)', path.read_text()):
            if not (ROOT / resource).exists():
                errors.append(f"{path.relative_to(ROOT)}: missing res://{resource}")

    for path in [ROOT / "AGENTS.md", *[p for folder in ("game", "assets", "networking", "docs", "tests") for p in (ROOT / folder).rglob("AGENTS.md")]]:
        budget = 4096 if path.parent == ROOT else 2048
        if path.stat().st_size > budget:
            errors.append(f"{path.relative_to(ROOT)} exceeds instruction budget ({budget} bytes)")

    docs = [ROOT / "README.md", *(ROOT / "docs").rglob("*.md"), ROOT / "networking/README.md"]
    for path in docs:
        for target in re.findall(r'\]\(([^)]+)\)', path.read_text()):
            if "://" in target or target.startswith("#"):
                continue
            if not (path.parent / target.split("#")[0]).exists():
                errors.append(f"{path.relative_to(ROOT)}: broken documentation link {target}")

    for error in errors:
        print(f"FAIL: {error}", file=sys.stderr)
    print(f"Architecture check: {'FAIL' if errors else 'PASS'} ({len(scripts)} scripts)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
