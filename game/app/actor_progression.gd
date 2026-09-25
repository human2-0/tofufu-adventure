class_name ActorProgression
extends Node
## Explicit bridge from confirmed combat events to stats and presentation.

var actor: Player
var combat: PlayerCombat
var hud: HUD
var equipment: CharacterEquipment:
	set(value):
		if equipment != null and equipment.changed.is_connected(_apply): equipment.changed.disconnect(_apply)
		equipment = value
		if equipment != null: equipment.changed.connect(_apply)
		if is_inside_tree(): _apply()
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
	if equipment != null: equipment.wearer_level = progress.level()
	var set_id := equipment.complete_set() if equipment != null else ""
	actor.set_collision_mask_value(JungleWorld.GATE_LAYER, progress.level() < JungleWorld.ENTRY_LEVEL)
	actor.motor.walk_multiplier = progress.walk_multiplier() * ApparelSetBonus.walk(set_id)
	actor.motor.dash_distance_multiplier = ApparelSetBonus.dash(set_id)
	actor.motor.jump_launch_multiplier = ApparelSetBonus.jump_launch(set_id)
	combat.sword_damage_multiplier = progress.damage_multiplier("sword") * ApparelSetBonus.melee_damage(set_id)
	combat.fist_damage_multiplier = progress.damage_multiplier("fist") * ApparelSetBonus.melee_damage(set_id)
	combat.attack_speed_multiplier = progress.attack_multiplier()
	combat.gun.attack_speed_multiplier = progress.attack_multiplier() * ApparelSetBonus.shooting_speed(set_id)
	combat.gun.damage_multiplier = progress.damage_multiplier("shooting") * ApparelSetBonus.ranged_damage(set_id)
	combat.sotjet.attack_speed_multiplier = progress.attack_multiplier() * ApparelSetBonus.shooting_speed(set_id)
	combat.sotjet.range_multiplier = progress.shooting_range_multiplier()
	combat.sotjet.flow.push_multiplier = progress.shooting_push_multiplier()
	combat.sotjet.flow.damage_multiplier = progress.damage_multiplier("shooting") * ApparelSetBonus.ranged_damage(set_id)
	combat.gun.spread_multiplier = progress.shooting_spread_multiplier()
	combat.incoming_damage_multiplier = progress.incoming_multiplier()
	if hud != null:
		hud.show_character(progress.display())
		if progress.level() > _level: hud.announce("Level %d / Stronger hits, defence and quicker steps!" % progress.level())
	_level = progress.level()
