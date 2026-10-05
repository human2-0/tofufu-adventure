class_name BarnPeace
extends RefCounted
## App combat boundary: visitors inside the barn cannot attack or receive damage.

static func contains(game: Node3D, at: Vector3) -> bool:
	return MeadowBarn.contains(game.world.seed_bank, at)

static func prepare(game: Node3D, actor: Player, combat: PlayerCombat, command: PlayerCommand) -> void:
	if not contains(game, actor.global_position): return
	combat.reset()
	command.attack_held = false
	command.punch_held = false
	command.guard_held = false
