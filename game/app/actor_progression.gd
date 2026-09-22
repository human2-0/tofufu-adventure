class_name ActorProgression
extends Node
## Explicit bridge from confirmed combat events to stats and presentation.

var actor: Player
var combat: PlayerCombat
var hud: HUD
var progress := CharacterProgress.new()
var _level: int = 1

func _ready() -> void:
	combat.weapon_trained.connect(progress.weapon_hit)
	combat.gun.weapon_trained.connect(progress.weapon_hit)
	combat.sotjet.weapon_trained.connect(progress.weapon_hit)
	combat.equipment.defended.connect(progress.defended)
	progress.changed.connect(_apply)
	_apply()

func _apply() -> void:
	actor.set_collision_mask_value(JungleWorld.GATE_LAYER, progress.level() < JungleWorld.ENTRY_LEVEL)
	actor.motor.walk_multiplier = progress.walk_multiplier()
	combat.sword_damage_multiplier = progress.damage_multiplier("sword")
	combat.fist_damage_multiplier = progress.damage_multiplier("fist")
	combat.attack_speed_multiplier = progress.attack_multiplier()
	combat.gun.attack_speed_multiplier = progress.attack_multiplier()
	combat.gun.damage_multiplier = progress.damage_multiplier("shooting")
	combat.sotjet.attack_speed_multiplier = progress.attack_multiplier()
	combat.sotjet.range_multiplier = progress.shooting_range_multiplier()
	combat.sotjet.flow.damage_multiplier = progress.damage_multiplier("shooting")
	combat.gun.spread_multiplier = progress.shooting_spread_multiplier()
	combat.incoming_damage_multiplier = progress.incoming_multiplier()
	if hud != null:
		hud.show_character(progress.display())
		if progress.level() > _level: hud.announce("Level %d / Stronger hits, defence and quicker steps!" % progress.level())
	_level = progress.level()
