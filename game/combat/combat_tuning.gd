class_name CombatTuning
extends Resource
## Authored values, shared read-only by each combat instance.

@export var maximum_health: float = 100.0
@export var charge_seconds: float = 0.85
@export var light_damage: float = 10.0
@export var heavy_damage: float = 30.0
@export var attack_cooldown: float = 0.28
@export var soybean_healing: float = 20.0

@export_group("Knife rhythm")
@export var combo_window_seconds: float = 1.15
@export var combo_stab_hold_seconds: float = 0.26
@export var combo_stab_damage: float = 15.0
@export var combo_stab_seconds: float = 0.3
@export_range(1, 10) var combo_max_count: int = 5
@export_range(0.0, 1.0, 0.01) var combo_critical_chance_per_hit: float = 0.1
@export_range(0.0, 1.0, 0.01) var combo_critical_chance_cap: float = 0.5
@export_range(1.0, 3.0, 0.05) var combo_critical_damage_multiplier: float = 1.75
@export var air_slash_damage: float = 20.0
@export var air_slash_seconds: float = 0.34
@export var launcher_damage: float = 25.0
@export var launcher_seconds: float = 0.42
@export var launcher_lift: float = 8.0
@export_group("Knife clash")
@export var clash_margin: float = 0.12
@export var clash_recovery_seconds: float = 0.16
@export var clash_dodge_seconds: float = 0.2

@export_group("Sword geometry (world units)")
@export var blade_length: float = 0.65
@export var blade_width: float = 0.12
@export var blade_thickness: float = 0.08
@export var grip_length: float = 0.16
@export var hand_height: float = 0.48
@export var hand_radius: float = 0.42
@export_group("Sproutwood staff")
@export var knife_power: float = 10.0
@export var staff_power: float = 5.0
@export var staff_length: float = 1.2
@export var staff_width: float = 0.16
@export var staff_tornado_seconds: float = 0.72
@export var staff_tornado_cooldown: float = 0.9
@export var staff_tornado_damage: float = 5.0
@export_group("Slash")
@export var swing_seconds: float = 0.38
@export var heavy_swing_seconds: float = 0.48
@export var light_arc_degrees: float = 130.0
@export var heavy_arc_degrees: float = 170.0
@export var idle_pitch_degrees: float = 68.0
@export var cut_start: float = 0.22
@export var cut_end: float = 0.78

@export_group("Defence and fists")
@export var guard_half_angle: float = 55.0
@export var punch_damage: float = 12.0
@export var punch_reach: float = 1.35
@export var punch_cooldown: float = 0.38

@export_group("Soybean gun")
@export var bean_damage: float = 20.0
@export var bean_head_damage: float = 40.0
@export var bean_speed: float = 60.0
@export var gun_cooldown: float = 0.18
@export var hip_spread_degrees: float = 5.0
@export var aim_spread_degrees: float = 0.35
@export var recoil_per_shot: float = 0.14
@export var aim_recoil_spread: float = 2.6
@export var hip_recoil_spread: float = 3.0
@export var recoil_recovery_delay: float = 0.12
@export var recoil_recovery_speed: float = 1.8
@export var muzzle_height: float = 0.78
@export var muzzle_side: float = 0.32
@export var muzzle_forward: float = 0.46
