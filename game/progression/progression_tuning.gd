class_name ProgressionTuning
extends Resource
## Shared authored balance; never holds mutable character progress.

@export_group("Practice curve")
@export_range(1, 1000) var first_practice_cost: int = 20
@export_range(1.01, 1.12, 0.01) var practice_growth: float = 1.1
@export_range(1, 10) var shooting_practice_multiplier: int = 4
@export_range(0.0, 0.009, 0.001) var shooting_accuracy: float = 0.006
@export_group("Character EXP curve")
@export var first_experience_cost: int = 100
@export var experience_linear: int = 50
@export var experience_quadratic: int = 25
@export_group("Per-rank bonuses above level one")
@export var weapon_damage: float = 0.015
@export var character_damage: float = 0.01
@export var defence_reduction: float = 0.0035
@export var character_levels_per_defence: int = 5
@export var character_walk_speed: float = 0.002
@export var character_attack_speed: float = 0.002
@export var trained_attack_speed: float = 0.003
