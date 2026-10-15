#!/usr/bin/env python3
"""Exercise verification selection and failure reporting without starting Godot."""
import contextlib
import importlib.util
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[1] / "tools/verify.py"
spec = importlib.util.spec_from_file_location("verify", MODULE)
verify = importlib.util.module_from_spec(spec)
spec.loader.exec_module(verify)


class VerificationChecks(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.logs = Path(directory.name)
        self.output = io.StringIO()

    def run_main(self, args):
        with contextlib.redirect_stdout(self.output), contextlib.redirect_stderr(self.output), \
                patch.object(verify.subprocess, "run") as commands, \
                patch.object(verify, "find_godot", return_value="godot") as discovery, \
                patch.object(verify, "run_stage", return_value=0.1) as stages, \
                patch.object(verify.tempfile, "mkdtemp", return_value=str(self.logs)):
            verify.main(args)
        return commands, discovery, stages

    def test_list_needs_no_engine_or_checks(self):
        commands, discovery, stages = self.run_main(["--list"])
        commands.assert_not_called()
        discovery.assert_not_called()
        stages.assert_not_called()
        self.assertIn("motor: res://tests/test_player_motor.gd", self.output.getvalue())

    def test_quick_loads_import_and_scene_only(self):
        _, _, stages = self.run_main(["--quick"])
        self.assertEqual([call.args[1] for call in stages.call_args_list], ["import", "scene"])
        self.assertIn("Full suite was not run.", self.output.getvalue())

    def test_focused_deduplicates_and_keeps_catalog_order(self):
        _, _, stages = self.run_main(["--tests", "inventory", "item_tooltip", "inventory"])
        self.assertEqual([call.args[1] for call in stages.call_args_list],
                         ["import", "item_tooltip", "inventory"])
        self.assertIn("Focused checks passed", self.output.getvalue())

    def test_quick_adds_smoke_and_preserves_long_timeouts(self):
        _, _, stages = self.run_main(["--quick", "--tests", "factory_route"])
        calls = stages.call_args_list
        self.assertEqual([call.args[1] for call in calls], ["import", "factory_route", "scene"])
        self.assertEqual(calls[1].args[4], 240)

    def test_invalid_selection_stops_before_running_checks(self):
        for args in (["--tests", "inventroy"], ["--full", "--tests", "inventory"],
                     ["--quick", "--full"]):
            with self.subTest(args=args), patch.object(verify.subprocess, "run") as commands, \
                    contextlib.redirect_stderr(self.output), self.assertRaises(SystemExit) as error:
                verify.main(args)
            self.assertEqual(error.exception.code, 2)
            commands.assert_not_called()

    def test_default_and_explicit_full_keep_every_stage(self):
        expected = ["import", *[name for name, _, _ in verify.test_stages()]]
        for args in ([], ["--full"]):
            with self.subTest(args=args):
                _, _, stages = self.run_main(args)
                self.assertEqual([call.args[1] for call in stages.call_args_list], expected)
        self.assertIn("Full checks passed", self.output.getvalue())
        self.assertNotIn("Full suite was not run.", self.output.getvalue())

    def test_zero_exit_engine_errors_fail_and_retain_output(self):
        result = subprocess.CompletedProcess([], 0, "starting\n", "SCRIPT ERROR: broken\n")
        with patch.object(verify.subprocess, "run", return_value=result), \
                contextlib.redirect_stdout(self.output), self.assertRaisesRegex(RuntimeError, "failed"):
            verify.run_stage("godot", "broken", [], self.logs)
        self.assertEqual((self.logs / "broken.log").read_text(), result.stdout + result.stderr)

    def test_nonzero_exit_fails_without_error_marker(self):
        result = subprocess.CompletedProcess([], 1, "starting\n", "")
        with patch.object(verify.subprocess, "run", return_value=result), \
                contextlib.redirect_stdout(self.output), self.assertRaisesRegex(RuntimeError, "exit 1"):
            verify.run_stage("godot", "broken", [], self.logs)

    def test_timeout_retains_partial_output_and_identifies_stage(self):
        timeout = subprocess.TimeoutExpired("godot", 60, output=b"starting\n", stderr=b"stalled\n")
        with patch.object(verify.subprocess, "run", side_effect=timeout), \
                self.assertRaisesRegex(RuntimeError, "scene timed out; inspect"):
            verify.run_stage("godot", "scene", [], self.logs)
        self.assertEqual((self.logs / "scene.log").read_text(), "starting\nstalled\n")


if __name__ == "__main__":
    unittest.main()
