#!/usr/bin/env python3
"""Guardrails operate on recursive feature layouts, not one historical file tree."""
import contextlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest

RESOURCE = "res:" + "//"
MODULE = Path(__file__).resolve().parents[1] / "tools/check_architecture.py"
spec = importlib.util.spec_from_file_location("architecture", MODULE)
architecture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(architecture)


class ArchitectureChecks(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.previous_root = architecture.ROOT
        architecture.ROOT = self.root
        self.addCleanup(setattr, architecture, "ROOT", self.previous_root)
        for name in ("project.godot", "export_presets.cfg", "AGENTS.md", "README.md",
                     "networking/README.md", "tests/README.md"):
            self.write(name, "")

    def write(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    def check_result(self, expected, fragment=""):
        output = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            result = architecture.main()
        self.assertEqual(result, expected, output.getvalue())
        self.assertIn(fragment, output.getvalue())

    def test_runtime_budget_and_long_test_scenarios(self):
        self.write("game/combat/melee/example.gd", "# line\n" * 200)
        self.write("tests/test_example.gd", "# scenario\n" * 300)
        self.check_result(0)
        self.write("game/combat/melee/example.gd", "# line\n" * 201)
        self.check_result(1, "runtime script exceeds 200 lines")

    def test_adapter_budget(self):
        self.write("networking/custom/adapter.gd", "# line\n" * 201)
        self.check_result(1, "runtime script exceeds 200 lines")

    def test_nested_folders_keep_feature_boundaries(self):
        self.write("game/combat/melee/weapon.gd", "class_name TestWeapon\nextends RefCounted\n")
        self.write("game/combat/ranged/consumer.gd", "var weapon: TestWeapon\n")
        self.write("game/app/actors/wiring.gd", "var weapon: TestWeapon\n")
        self.check_result(0)
        self.write("game/ui/hud/readout.gd", "var weapon: TestWeapon\n")
        self.check_result(1, "cross-feature dependency on TestWeapon")

    def test_test_resource_paths_are_checked_after_moves(self):
        self.write("game/app/adventure/main.tscn", "")
        self.write("tests/test_scene.gd", f'const SCENE = preload("{RESOURCE}game/app/adventure/main.tscn")\n')
        self.check_result(0)
        self.write("tests/test_scene.gd", f'const SCENE = preload("{RESOURCE}game/app/main.tscn")\n')
        self.check_result(1, "missing res://game/app/main.tscn")

    def test_service_entry_scene_is_checked(self):
        self.write("deploy/server.service", f"ExecStart=godot --headless {RESOURCE}game/app/server.tscn")
        self.check_result(1, "missing res://game/app/server.tscn")
        self.write("game/app/server.tscn", "")
        self.check_result(0)

    def test_dependency_caches_are_skipped(self):
        self.write("networking/sidecar/node_modules/example/test.py", f'path = "{RESOURCE}not-a-project-resource"')
        self.write("networking/sidecar/node_modules/example/test.gd", "# line\n" * 300)
        self.check_result(0)


if __name__ == "__main__":
    unittest.main()
