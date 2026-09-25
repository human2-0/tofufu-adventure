#!/usr/bin/env python3
"""Import and exercise Godot; retain logs and fail even on zero-exit script errors."""
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def find_godot():
    override = os.environ.get("GODOT_BIN")
    if override:
        return override
    for name in ("godot", "godot4"):
        executable = shutil.which(name)
        if executable:
            return executable
    mac = Path("/Applications/Godot.app/Contents/MacOS/Godot")
    if mac.exists():
        return str(mac)
    raise RuntimeError("Godot not found. Set GODOT_BIN to the Godot 4.7 executable.")


def run_stage(godot, name, args, logs):
    command = [godot, "--headless", "--path", str(ROOT), "--log-file", str(logs / f"{name}.engine.log"), *args]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=60)
    output = result.stdout + result.stderr
    (logs / f"{name}.log").write_text(output)
    failed = result.returncode != 0 or re.search(r"(?:SCRIPT ERROR:|ERROR:|FAIL:)", output)
    if failed:
        print(output)
        raise RuntimeError(f"{name} failed (exit {result.returncode}); inspect {logs}")
    print(f"{name}: PASS")


def main():
    subprocess.run([sys.executable, str(ROOT / "tools/check_architecture.py")], check=True)
    godot = find_godot()
    logs = Path(tempfile.mkdtemp(prefix="tofufu-verify-"))
    print(f"Logs: {logs}", flush=True)
    run_stage(godot, "import", ["--editor", "--import"], logs)
    run_stage(godot, "coop_farming", ["--script", "res://tests/test_coop_farming.gd"], logs)
    run_stage(godot, "farming", ["--script", "res://tests/test_farming.gd"], logs)
    run_stage(godot, "jungle", ["--script", "res://tests/test_jungle.gd"], logs)
    run_stage(godot, "northern_biomes", ["--script", "res://tests/test_northern_biomes.gd"], logs)
    run_stage(godot, "map", ["--script", "res://tests/test_map.gd"], logs)
    run_stage(godot, "input", ["--script", "res://tests/test_input.gd"], logs)
    run_stage(godot, "motor", ["--script", "res://tests/test_player_motor.gd"], logs)
    run_stage(godot, "actor_collisions", ["--script", "res://tests/test_actor_collisions.gd"], logs)
    run_stage(godot, "jump", ["--script", "res://tests/test_jump.gd"], logs)
    run_stage(godot, "progression", ["--script", "res://tests/test_progression.gd"], logs)
    run_stage(godot, "combat", ["--script", "res://tests/test_combat.gd"], logs)
    run_stage(godot, "knife_combo", ["--script", "res://tests/test_knife_combo.gd"], logs)
    run_stage(godot, "melee_clash", ["--script", "res://tests/test_melee_clash.gd"], logs)
    run_stage(godot, "equipment", ["--script", "res://tests/test_equipment.gd"], logs)
    run_stage(godot, "loadout_shop", ["--script", "res://tests/test_loadout_shop.gd"], logs)
    run_stage(godot, "staff_combat", ["--script", "res://tests/test_staff_combat.gd"], logs)
    run_stage(godot, "backpack", ["--script", "res://tests/test_backpack.gd"], logs)
    run_stage(godot, "world_items", ["--script", "res://tests/test_world_items.gd"], logs)
    run_stage(godot, "inventory_input", ["--script", "res://tests/test_inventory_input.gd"], logs)
    run_stage(godot, "inventory", ["--script", "res://tests/test_inventory.gd"], logs)
    run_stage(godot, "seed_storage", ["--script", "res://tests/test_seed_storage.gd"], logs)
    run_stage(godot, "currency", ["--script", "res://tests/test_currency.gd"], logs)
    run_stage(godot, "factory_route", ["--script", "res://tests/test_factory_route.gd"], logs)
    run_stage(godot, "tofu_dungeon", ["--script", "res://tests/test_tofu_dungeon.gd"], logs)
    run_stage(godot, "tofu_dungeon_coop", ["--script", "res://tests/test_tofu_dungeon_coop.gd"], logs)
    run_stage(godot, "gun_recoil", ["--script", "res://tests/test_gun_recoil.gd"], logs)
    run_stage(godot, "first_person", ["--script", "res://tests/test_first_person.gd"], logs)
    run_stage(godot, "soy_flight", ["--script", "res://tests/test_soy_flight.gd"], logs)
    run_stage(godot, "soy_gun", ["--script", "res://tests/test_soy_gun.gd"], logs)
    run_stage(godot, "sotjet", ["--script", "res://tests/test_sotjet.gd"], logs)
    run_stage(godot, "sotjet_coop", ["--script", "res://tests/test_sotjet_coop.gd"], logs)
    run_stage(godot, "sword", ["--script", "res://tests/test_sword.gd"], logs)
    run_stage(godot, "sandbox", ["--script", "res://tests/test_sandbox.gd"], logs)
    run_stage(godot, "farm_combat", ["--script", "res://tests/test_farm_combat.gd"], logs)
    run_stage(godot, "snail", ["--script", "res://tests/test_snail.gd"], logs)
    run_stage(godot, "river", ["--script", "res://tests/test_river.gd"], logs)
    run_stage(godot, "sky", ["--script", "res://tests/test_sky.gd"], logs)
    run_stage(godot, "weather", ["--script", "res://tests/test_weather.gd"], logs)
    run_stage(godot, "pod_escape", ["--script", "res://tests/test_pod_escape.gd"], logs)
    run_stage(godot, "session_transport", ["--script", "res://tests/test_session_transport.gd"], logs)
    run_stage(godot, "oracle", ["--script", "res://tests/test_oracle.gd"], logs)
    run_stage(godot, "coop_protocol", ["--script", "res://tests/test_coop_protocol.gd"], logs)
    run_stage(godot, "coop_gameplay", ["--script", "res://tests/test_coop_gameplay.gd"], logs)
    run_stage(godot, "coop_response", ["--script", "res://tests/test_coop_response.gd"], logs)
    run_stage(godot, "coop_opening", ["--script", "res://tests/test_coop_opening.gd"], logs)
    run_stage(godot, "coop_launch", ["--script", "res://tests/test_coop_launch.gd"], logs)
    run_stage(godot, "chat", ["--script", "res://tests/test_chat.gd"], logs)
    run_stage(godot, "coop_scene", ["--script", "res://tests/test_coop_scene.gd"], logs)
    run_stage(godot, "frontend", ["--script", "res://tests/test_frontend.gd"], logs)
    run_stage(godot, "scene", ["--script", "res://tests/test_scene.gd"], logs)
    print("All automated checks passed. Visual/NAT checks remain separate.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
