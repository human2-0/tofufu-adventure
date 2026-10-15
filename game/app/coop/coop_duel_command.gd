class_name CoopDuelCommand
extends RefCounted
## Arena participants cannot use world shortcuts or attack through a countdown.

static func prepare(member: CoopActor, command: PlayerCommand) -> void:
	if member.duel == null or not member.duel.is_participant(member.duel.session.roster.actor_identity(member.actor)): return
	command.camp_pressed = false
	command.time_pressed = false
	command.drop_pressed = false
	command.pickup_pressed = false
	command.use_healing_1 = false
	command.use_healing_2 = false
	command.use_healing_3 = false
	command.use_healing_4 = false
	if member.duel.phase == "fight": return
	command.attack_held = false
	command.guard_held = false
	command.punch_held = false
	command.weapon_slot = 0
	command.cancel_actions = true
