#!/usr/bin/env python3
"""Import and exercise Godot; retain logs and fail even on zero-exit script errors."""
from pathlib import Path
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time

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


def run_stage(godot, name, args, logs, timeout_seconds=60, verbose=False):
    command = [godot, "--headless", "--path", str(ROOT), "--log-file", str(logs / f"{name}.engine.log"), *args]
    timeout_scale = float(os.environ.get("TOFUFU_VERIFY_TIMEOUT_SCALE", "1"))
    if not 1 <= timeout_scale <= 5:
        raise RuntimeError("TOFUFU_VERIFY_TIMEOUT_SCALE must be between 1 and 5")
    started = time.monotonic()
    try:
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                                timeout=timeout_seconds * timeout_scale)
    except subprocess.TimeoutExpired as error:
        output = "".join(part.decode(errors="replace") if isinstance(part, bytes) else part or ""
                         for part in (error.stdout, error.stderr))
        (logs / f"{name}.log").write_text(output)
        raise RuntimeError(f"{name} timed out; inspect {logs}") from error
    output = result.stdout + result.stderr
    (logs / f"{name}.log").write_text(output)
    failed = result.returncode != 0 or re.search(r"(?:SCRIPT ERROR:|ERROR:|FAIL:)", output)
    if failed:
        print(output)
        raise RuntimeError(f"{name} failed (exit {result.returncode}); inspect {logs}")
    elapsed = time.monotonic() - started
    if verbose:
        print(f"{name}: PASS ({elapsed:.1f}s)", flush=True)
    return elapsed


def test_stages():
    yield "tofufu_alignment", ["--script", "res://tests/test_tofufu_alignment.gd"], 60
    yield "battle_migration", ["--script", "res://tests/test_battle_migration.gd"], 60
    yield "battle_royale", ["--script", "res://tests/test_battle_royale.gd"], 60
    yield "battle_combat", ["--script", "res://tests/test_battle_combat.gd"], 60
    yield "battle_survival", ["--script", "res://tests/test_battle_survival.gd"], 180
    yield "battle_hud", ["--script", "res://tests/test_battle_hud.gd"], 90
    yield "battle_radar", ["--script", "res://tests/test_battle_radar.gd"], 60
    yield "battle_mobs", ["--script", "res://tests/test_battle_mobs.gd"], 180
    yield "battle_loop", ["--script", "res://tests/test_battle_loop.gd"], 90
    yield "battle_squad", ["--script", "res://tests/test_battle_squad.gd"], 90
    yield "battle_rematch", ["--script", "res://tests/test_battle_rematch.gd"], 300
    yield "battle_inventory", ["--script", "res://tests/test_battle_inventory.gd"], 180
    yield "battle_deployment", ["--script", "res://tests/test_battle_deployment.gd"], 180
    yield "battle_cpu", ["--script", "res://tests/test_battle_cpu.gd"], 180
    yield "battle_game", ["--script", "res://tests/test_battle_game.gd"], 180
    yield "gigalopolis", ["--script", "res://tests/test_gigalopolis.gd"], 180
    yield "city_loot", ["--script", "res://tests/test_city_loot.gd"], 240
    yield "coop_city_loot", ["--script", "res://tests/test_coop_city_loot.gd"], 180
    yield "gigalopolis_east", ["--script", "res://tests/test_gigalopolis_east.gd"], 180
    yield "skin_test", ["--script", "res://tests/test_skin_test.gd"], 90
    yield "unarmed_art", ["--script", "res://tests/test_unarmed_art.gd"], 60
    yield "fufu_3d", ["--script", "res://tests/test_fufu_3d.gd"], 90
    yield "angel_bow", ["--script", "res://tests/test_angel_bow.gd"], 90
    yield "coop_angel_bow", ["--script", "res://tests/test_coop_angel_bow.gd"], 120
    yield "bengal_dash", ["--script", "res://tests/test_bengal_dash.gd"], 60
    yield "bengal_vfx", ["--script", "res://tests/test_bengal_vfx.gd"], 60
    yield "bengal", ["--script", "res://tests/test_bengal.gd"], 120
    yield "coop_bengal", ["--script", "res://tests/test_coop_bengal.gd"], 180
    yield "localization", ["--script", "res://tests/test_localization.gd"], 60
    yield "weapon_enhancement", ["--script", "res://tests/test_weapon_enhancement.gd"], 120
    yield "item_tooltip", ["--script", "res://tests/test_item_tooltip.gd"], 60
    yield "save_modes", ["--script", "res://tests/test_save_modes.gd"], 60
    # Two three-world scenarios include a sustained full-party harvest check.
    yield "coop_farming", ["--script", "res://tests/test_coop_farming.gd"], 240
    yield "meadow_reorg", ["--script", "res://tests/test_meadow_reorg.gd"], 60
    yield "meadow_meshes", ["--script", "res://tests/test_meadow_meshes.gd"], 60
    yield "farming", ["--script", "res://tests/test_farming.gd"], 60
    yield "soy_save_spots", ["--script", "res://tests/test_soy_save_spots.gd"], 150
    yield "coop_soy_save_spots", ["--script", "res://tests/test_coop_soy_save_spots.gd"], 240
    yield "soy_plant", ["--script", "res://tests/test_soy_plant.gd"], 60
    # Builds two complete adventure worlds before the tick-based flight scenario.
    yield "coop_parrot_travel", ["--script", "res://tests/test_coop_parrot_travel.gd"], 120
    yield "parrot_travel", ["--script", "res://tests/test_parrot_travel.gd"], 60
    yield "parrot_art", ["--script", "res://tests/test_parrot_art.gd"], 60
    yield "cloud_realm", ["--script", "res://tests/test_cloud_realm.gd"], 120
    yield "cloud_realm_art", ["--script", "res://tests/test_cloud_realm_art.gd"], 60
    yield "cloud_heaven", ["--script", "res://tests/test_cloud_heaven.gd"], 60
    yield "celestial", ["--script", "res://tests/test_celestial.gd"], 60
    yield "lava_king_art", ["--script", "res://tests/test_lava_king_art.gd"], 60
    yield "volcanic_expansion", ["--script", "res://tests/test_volcanic_expansion.gd"], 120
    yield "castle_stairs", ["--script", "res://tests/test_castle_stairs.gd"], 150
    yield "coop_castle", ["--script", "res://tests/test_coop_castle.gd"], 60
    yield "castle_adventure", ["--script", "res://tests/test_castle_adventure.gd"], 60
    yield "castle_challenge", ["--script", "res://tests/test_castle_challenge.gd"], 60
    yield "volcanic", ["--script", "res://tests/test_volcanic.gd"], 180
    yield "dofufu_city", ["--script", "res://tests/test_dofufu_city.gd"], 180
    yield "mountain_retreat", ["--script", "res://tests/test_mountain_retreat.gd"], 120
    yield "groatfields", ["--script", "res://tests/test_groatfields.gd"], 60
    yield "coop_groatfields", ["--script", "res://tests/test_coop_groatfields.gd"], 120
    yield "jungle", ["--script", "res://tests/test_jungle.gd"], 60
    yield "waterfall", ["--script", "res://tests/test_waterfall.gd"], 60
    yield "northern_biomes", ["--script", "res://tests/test_northern_biomes.gd"], 60
    yield "personal_map_transfer", ["--script", "res://tests/test_personal_map_transfer.gd"], 60
    yield "map_exploration", ["--script", "res://tests/test_map_exploration.gd"], 60
    yield "map", ["--script", "res://tests/test_map.gd"], 60
    yield "input", ["--script", "res://tests/test_input.gd"], 60
    yield "motor", ["--script", "res://tests/test_player_motor.gd"], 60
    yield "heavy_movement", ["--script", "res://tests/test_heavy_movement.gd"], 60
    yield "render_budget", ["--script", "res://tests/test_render_budget.gd"], 60
    yield "occlusion", ["--script", "res://tests/test_occlusion.gd"], 60
    yield "scenery_batch", ["--script", "res://tests/test_scenery_batch.gd"], 60
    yield "mob_rest", ["--script", "res://tests/test_mob_rest.gd"], 60
    yield "grass", ["--script", "res://tests/test_grass.gd"], 60
    yield "world_life", ["--script", "res://tests/test_world_life.gd"], 60
    yield "apple_trees", ["--script", "res://tests/test_apple_trees.gd"], 60
    yield "apple_pickup", ["--script", "res://tests/test_apple_pickup.gd"], 60
    yield "actor_collisions", ["--script", "res://tests/test_actor_collisions.gd"], 60
    yield "jump", ["--script", "res://tests/test_jump.gd"], 60
    yield "vitals", ["--script", "res://tests/test_vitals.gd"], 60
    yield "progression", ["--script", "res://tests/test_progression.gd"], 60
    yield "character_details", ["--script", "res://tests/test_character_details.gd"], 180
    yield "combat", ["--script", "res://tests/test_combat.gd"], 60
    yield "knife_combo", ["--script", "res://tests/test_knife_combo.gd"], 60
    yield "melee_flow", ["--script", "res://tests/test_melee_flow.gd"], 60
    yield "melee_clash", ["--script", "res://tests/test_melee_clash.gd"], 60
    yield "equipment", ["--script", "res://tests/test_equipment.gd"], 60
    yield "loadout_shop", ["--script", "res://tests/test_loadout_shop.gd"], 60
    yield "nori_katana", ["--script", "res://tests/test_nori_katana.gd"], 60
    yield "edamame_sword", ["--script", "res://tests/test_edamame_sword.gd"], 60
    yield "staff_combat", ["--script", "res://tests/test_staff_combat.gd"], 60
    yield "backpack", ["--script", "res://tests/test_backpack.gd"], 60
    yield "world_items", ["--script", "res://tests/test_world_items.gd"], 60
    yield "depot_focus", ["--script", "res://tests/test_depot_focus.gd"], 60
    yield "inventory_input", ["--script", "res://tests/test_inventory_input.gd"], 60
    yield "inventory", ["--script", "res://tests/test_inventory.gd"], 60
    yield "seed_storage", ["--script", "res://tests/test_seed_storage.gd"], 60
    yield "coop_storage", ["--script", "res://tests/test_coop_storage.gd"], 60
    yield "currency", ["--script", "res://tests/test_currency.gd"], 60
    yield "factory_route", ["--script", "res://tests/test_factory_route.gd"], 240
    yield "tofu_dungeon", ["--script", "res://tests/test_tofu_dungeon.gd"], 60
    yield "tofu_dungeon_coop", ["--script", "res://tests/test_tofu_dungeon_coop.gd"], 60
    for name in ["tofu_boss_coop", "factory_recovery", "factory_presentation", "factory_surfaces", "factory_reactivity", "factory_stashes", "factory_handling", "tofu_production_views", "tofu_sorting_lab_rules", "tofu_production_rules", "tofu_dungeon_attempt", "tofu_reward_ledger", "tofu_puzzle_protocol", "dungeon_puzzle_runtime", "dungeon_ui", "factory_soy_fighter", "dofufu"]:
        yield name, ["--script", f"res://tests/test_{name}.gd"], 60
    yield "tofu_dungeon_active", ["--script", "res://tests/test_tofu_dungeon_active.gd"], 60
    yield "tofu_dungeon_active_coop", ["--script", "res://tests/test_tofu_dungeon_active_coop.gd"], 60
    yield "gun_recoil", ["--script", "res://tests/test_gun_recoil.gd"], 60
    yield "first_person", ["--script", "res://tests/test_first_person.gd"], 60
    yield "soy_flight", ["--script", "res://tests/test_soy_flight.gd"], 60
    yield "soy_gun", ["--script", "res://tests/test_soy_gun.gd"], 60
    yield "soy_reload", ["--script", "res://tests/test_soy_reload.gd"], 60
    yield "gun_run_pose", ["--script", "res://tests/test_gun_run_pose.gd"], 60
    yield "sotjet", ["--script", "res://tests/test_sotjet.gd"], 60
    yield "sotjet_coop", ["--script", "res://tests/test_sotjet_coop.gd"], 60
    yield "right_hand", ["--script", "res://tests/test_right_hand.gd"], 60
    yield "sword", ["--script", "res://tests/test_sword.gd"], 60
    yield "sandbox", ["--script", "res://tests/test_sandbox.gd"], 60
    yield "armored_shell", ["--script", "res://tests/test_armored_shell.gd"], 60
    yield "farm_combat", ["--script", "res://tests/test_farm_combat.gd"], 60
    yield "wild_bee", ["--script", "res://tests/test_wild_bee.gd"], 60
    yield "coop_wild_bee", ["--script", "res://tests/test_coop_wild_bee.gd"], 60
    yield "snail", ["--script", "res://tests/test_snail.gd"], 60
    yield "world_contours", ["--script", "res://tests/test_world_contours.gd"], 60
    yield "ocean", ["--script", "res://tests/test_ocean.gd"], 60
    yield "coop_ocean", ["--script", "res://tests/test_coop_ocean.gd"], 60
    yield "river", ["--script", "res://tests/test_river.gd"], 60
    yield "sky", ["--script", "res://tests/test_sky.gd"], 60
    yield "weather", ["--script", "res://tests/test_weather.gd"], 60
    yield "weather_exposure", ["--script", "res://tests/test_weather_exposure.gd"], 60
    yield "pod_escape", ["--script", "res://tests/test_pod_escape.gd"], 60
    yield "session_transport", ["--script", "res://tests/test_session_transport.gd"], 60
    yield "oracle", ["--script", "res://tests/test_oracle.gd"], 120
    yield "public_multiplayer", ["--script", "res://tests/test_public_multiplayer.gd"], 120
    yield "coop_protocol", ["--script", "res://tests/test_coop_protocol.gd"], 60
    yield "snapshot_channel", ["--script", "res://tests/test_snapshot_channel.gd"], 60
    yield "arena", ["--script", "res://tests/test_arena.gd"], 60
    yield "solo_arena", ["--script", "res://tests/test_solo_arena.gd"], 120
    yield "coop_gameplay", ["--script", "res://tests/test_coop_gameplay.gd"], 60
    yield "coop_response", ["--script", "res://tests/test_coop_response.gd"], 60
    yield "coop_opening", ["--script", "res://tests/test_coop_opening.gd"], 60
    yield "coop_launch", ["--script", "res://tests/test_coop_launch.gd"], 60
    yield "chat", ["--script", "res://tests/test_chat.gd"], 60
    yield "coop_scene", ["--script", "res://tests/test_coop_scene.gd"], 60
    yield "update_log", ["--script", "res://tests/test_update_log.gd"], 60
    yield "landing", ["--script", "res://tests/test_landing.gd"], 60
    yield "lobby", ["--script", "res://tests/test_lobby.gd"], 60
    yield "frontend", ["--script", "res://tests/test_frontend.gd"], 60
    yield "scene", ["--script", "res://tests/test_scene.gd"], 60


def parse_options(argv, stages):
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--quick", action="store_true",
                      help="architecture, Godot import and scene smoke test")
    mode.add_argument("--full", action="store_true", help="all checks (also the default)")
    parser.add_argument("--tests", nargs="+", metavar="NAME",
                        help="run selected tests; may be combined with --quick")
    parser.add_argument("--list", action="store_true", help="list test names without running checks")
    parser.add_argument("--verbose", action="store_true", help="print each successful stage and duration")
    options = parser.parse_args(argv)
    if options.full and options.tests:
        parser.error("--full cannot be combined with --tests")
    unknown = set(options.tests or ()) - {name for name, _, _ in stages}
    if unknown:
        parser.error(f"unknown tests: {', '.join(sorted(unknown))}; use --list for names")
    return options


def main(argv=None):
    stages = list(test_stages())
    options = parse_options(argv, stages)
    if options.list:
        for name, args, timeout in stages:
            print(f"{name}: {args[-1]} (timeout {timeout}s)")
        return
    selected = set(options.tests or ())
    if options.quick:
        selected.add("scene")
    scope = "Quick" if options.quick else "Focused" if options.tests else "Full"
    if selected:
        stages = [stage for stage in stages if stage[0] in selected]
    started = time.monotonic()
    print(f"{scope} verification: architecture, import, {len(stages)} Godot tests", flush=True)
    subprocess.run([sys.executable, str(ROOT / "tools/check_architecture.py")], check=True)
    subprocess.run([sys.executable, str(ROOT / "tests/test_architecture.py")], check=True)
    subprocess.run([sys.executable, str(ROOT / "tests/test_verify.py")], check=True)
    godot = find_godot()
    logs = Path(tempfile.mkdtemp(prefix="tofufu-verify-"))
    print(f"Logs: {logs}", flush=True)
    durations = [("import", run_stage(godot, "import", ["--editor", "--import"], logs,
                                    verbose=options.verbose))]
    for name, args, timeout in stages:
        durations.append((name, run_stage(godot, name, args, logs, timeout,
                                         verbose=options.verbose)))
    elapsed = time.monotonic() - started
    slowest = sorted(durations, key=lambda stage: stage[1], reverse=True)[:3]
    print(f"{scope} checks passed in {elapsed:.1f}s ({len(stages)} Godot tests). "
          "Visual/NAT checks remain separate.")
    print("Slowest stages: " + ", ".join(f"{name} {duration:.1f}s" for name, duration in slowest))
    if scope != "Full":
        print("Full suite was not run.")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
