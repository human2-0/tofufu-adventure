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


def run_stage(godot, name, args, logs, timeout_seconds=60):
    command = [godot, "--headless", "--path", str(ROOT), "--log-file", str(logs / f"{name}.engine.log"), *args]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=timeout_seconds)
    output = result.stdout + result.stderr
    (logs / f"{name}.log").write_text(output)
    failed = result.returncode != 0 or re.search(r"(?:SCRIPT ERROR:|ERROR:|FAIL:)", output)
    if failed:
        print(output)
        raise RuntimeError(f"{name} failed (exit {result.returncode}); inspect {logs}")
    print(f"{name}: PASS")


def main():
    subprocess.run([sys.executable, str(ROOT / "tools/check_architecture.py")], check=True)
    subprocess.run([sys.executable, str(ROOT / "tests/test_architecture.py")], check=True)
    godot = find_godot()
    logs = Path(tempfile.mkdtemp(prefix="tofufu-verify-"))
    print(f"Logs: {logs}", flush=True)
    run_stage(godot, "import", ["--editor", "--import"], logs)
    # Two three-world scenarios include a sustained full-party harvest check.
    run_stage(godot, "coop_farming", ["--script", "res://tests/test_coop_farming.gd"], logs, timeout_seconds=120)
    run_stage(godot, "meadow_reorg", ["--script", "res://tests/test_meadow_reorg.gd"], logs)
    run_stage(godot, "farming", ["--script", "res://tests/test_farming.gd"], logs)
    run_stage(godot, "soy_plant", ["--script", "res://tests/test_soy_plant.gd"], logs)
    run_stage(godot, "coop_parrot_travel", ["--script", "res://tests/test_coop_parrot_travel.gd"], logs)
    run_stage(godot, "parrot_travel", ["--script", "res://tests/test_parrot_travel.gd"], logs)
    run_stage(godot, "cloud_realm", ["--script", "res://tests/test_cloud_realm.gd"], logs)
    run_stage(godot, "lava_king_art", ["--script", "res://tests/test_lava_king_art.gd"], logs)
    run_stage(godot, "volcanic_expansion", ["--script", "res://tests/test_volcanic_expansion.gd"], logs, timeout_seconds=120)
    run_stage(godot, "volcanic", ["--script", "res://tests/test_volcanic.gd"], logs, timeout_seconds=120)
    run_stage(godot, "jungle", ["--script", "res://tests/test_jungle.gd"], logs)
    run_stage(godot, "waterfall", ["--script", "res://tests/test_waterfall.gd"], logs)
    run_stage(godot, "northern_biomes", ["--script", "res://tests/test_northern_biomes.gd"], logs)
    run_stage(godot, "map_exploration", ["--script", "res://tests/test_map_exploration.gd"], logs)
    run_stage(godot, "map", ["--script", "res://tests/test_map.gd"], logs)
    run_stage(godot, "input", ["--script", "res://tests/test_input.gd"], logs)
    run_stage(godot, "motor", ["--script", "res://tests/test_player_motor.gd"], logs)
    run_stage(godot, "heavy_movement", ["--script", "res://tests/test_heavy_movement.gd"], logs)
    run_stage(godot, "render_budget", ["--script", "res://tests/test_render_budget.gd"], logs)
    run_stage(godot, "grass", ["--script", "res://tests/test_grass.gd"], logs)
    run_stage(godot, "world_life", ["--script", "res://tests/test_world_life.gd"], logs)
    run_stage(godot, "apple_trees", ["--script", "res://tests/test_apple_trees.gd"], logs)
    run_stage(godot, "apple_pickup", ["--script", "res://tests/test_apple_pickup.gd"], logs)
    run_stage(godot, "actor_collisions", ["--script", "res://tests/test_actor_collisions.gd"], logs)
    run_stage(godot, "jump", ["--script", "res://tests/test_jump.gd"], logs)
    run_stage(godot, "vitals", ["--script", "res://tests/test_vitals.gd"], logs)
    run_stage(godot, "progression", ["--script", "res://tests/test_progression.gd"], logs)
    run_stage(godot, "combat", ["--script", "res://tests/test_combat.gd"], logs)
    run_stage(godot, "knife_combo", ["--script", "res://tests/test_knife_combo.gd"], logs)
    run_stage(godot, "melee_clash", ["--script", "res://tests/test_melee_clash.gd"], logs)
    run_stage(godot, "equipment", ["--script", "res://tests/test_equipment.gd"], logs)
    run_stage(godot, "loadout_shop", ["--script", "res://tests/test_loadout_shop.gd"], logs)
    run_stage(godot, "nori_katana", ["--script", "res://tests/test_nori_katana.gd"], logs)
    run_stage(godot, "edamame_sword", ["--script", "res://tests/test_edamame_sword.gd"], logs)
    run_stage(godot, "staff_combat", ["--script", "res://tests/test_staff_combat.gd"], logs)
    run_stage(godot, "backpack", ["--script", "res://tests/test_backpack.gd"], logs)
    run_stage(godot, "world_items", ["--script", "res://tests/test_world_items.gd"], logs)
    run_stage(godot, "depot_focus", ["--script", "res://tests/test_depot_focus.gd"], logs)
    run_stage(godot, "inventory_input", ["--script", "res://tests/test_inventory_input.gd"], logs)
    run_stage(godot, "inventory", ["--script", "res://tests/test_inventory.gd"], logs)
    run_stage(godot, "seed_storage", ["--script", "res://tests/test_seed_storage.gd"], logs)
    run_stage(godot, "currency", ["--script", "res://tests/test_currency.gd"], logs)
    run_stage(godot, "factory_route", ["--script", "res://tests/test_factory_route.gd"], logs, timeout_seconds=240)
    run_stage(godot, "tofu_dungeon", ["--script", "res://tests/test_tofu_dungeon.gd"], logs)
    run_stage(godot, "tofu_dungeon_coop", ["--script", "res://tests/test_tofu_dungeon_coop.gd"], logs)
    for name in ["tofu_boss_coop", "factory_recovery", "factory_presentation", "tofu_production_views", "tofu_sorting_lab_rules", "tofu_production_rules", "tofu_dungeon_attempt", "tofu_reward_ledger", "tofu_puzzle_protocol", "dungeon_puzzle_runtime", "dungeon_ui", "factory_soy_fighter", "dofufu"]:
        run_stage(godot, name, ["--script", f"res://tests/test_{name}.gd"], logs)
    run_stage(godot, "tofu_dungeon_active", ["--script", "res://tests/test_tofu_dungeon_active.gd"], logs)
    run_stage(godot, "tofu_dungeon_active_coop", ["--script", "res://tests/test_tofu_dungeon_active_coop.gd"], logs)
    run_stage(godot, "gun_recoil", ["--script", "res://tests/test_gun_recoil.gd"], logs)
    run_stage(godot, "first_person", ["--script", "res://tests/test_first_person.gd"], logs)
    run_stage(godot, "soy_flight", ["--script", "res://tests/test_soy_flight.gd"], logs)
    run_stage(godot, "soy_gun", ["--script", "res://tests/test_soy_gun.gd"], logs)
    run_stage(godot, "soy_reload", ["--script", "res://tests/test_soy_reload.gd"], logs)
    run_stage(godot, "gun_run_pose", ["--script", "res://tests/test_gun_run_pose.gd"], logs)
    run_stage(godot, "sotjet", ["--script", "res://tests/test_sotjet.gd"], logs)
    run_stage(godot, "sotjet_coop", ["--script", "res://tests/test_sotjet_coop.gd"], logs)
    run_stage(godot, "right_hand", ["--script", "res://tests/test_right_hand.gd"], logs)
    run_stage(godot, "sword", ["--script", "res://tests/test_sword.gd"], logs)
    run_stage(godot, "sandbox", ["--script", "res://tests/test_sandbox.gd"], logs)
    run_stage(godot, "armored_shell", ["--script", "res://tests/test_armored_shell.gd"], logs)
    run_stage(godot, "farm_combat", ["--script", "res://tests/test_farm_combat.gd"], logs)
    run_stage(godot, "wild_bee", ["--script", "res://tests/test_wild_bee.gd"], logs)
    run_stage(godot, "coop_wild_bee", ["--script", "res://tests/test_coop_wild_bee.gd"], logs)
    run_stage(godot, "snail", ["--script", "res://tests/test_snail.gd"], logs)
    run_stage(godot, "world_contours", ["--script", "res://tests/test_world_contours.gd"], logs)
    run_stage(godot, "ocean", ["--script", "res://tests/test_ocean.gd"], logs)
    run_stage(godot, "coop_ocean", ["--script", "res://tests/test_coop_ocean.gd"], logs)
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
