class_name ActorCare
extends Node
## Authority measures ordinary ground travel and effective consumable recovery.

var progression: ActorProgression
var enabled: bool = true
var healing: PlayerHealing:
	set(value):
		if healing != null and healing.recovered.is_connected(_recovered): healing.recovered.disconnect(_recovered)
		healing = value
		if healing != null: healing.recovered.connect(_recovered)
var _last := Vector3.INF
var _metres: float = 0.0
var _healed: float = 0.0
var _ranks: Array[int] = [0, 0, 0]

func _ready() -> void:
	progression.actor.command_sampled.connect(_step)
	progression.actor.relocated.connect(_reset_travel)
	progression.progress.changed.connect(_milestones)

func _reset_travel() -> void:
	_last = Vector3.INF
	_metres = 0.0
	_healed = 0.0

func _step(command: PlayerCommand, delta: float) -> void:
	var actor := progression.actor
	var at := actor.global_position
	var previous := _last
	_last = at
	if not enabled or progression.combat.replica_view or not previous.is_finite(): return
	if command.move.is_zero_approx() or command.cancel_actions or not actor.is_on_floor(): return
	if actor.transport_active or actor.motor.is_dashing or actor.motor.impact.remaining > 0.0: return
	if progression.combat.owner_health.current <= 0.0: return
	var distance := Vector2(at.x - previous.x, at.z - previous.z).length()
	# Teleports, air travel and collision pushes cannot buy walking milestones.
	if distance > actor.tuning.run_speed * actor.motor.walk_multiplier * delta * 1.5 + 0.05: return
	_metres += distance
	if _metres >= 10.0:
		var units := floori(_metres)
		_metres -= units
		progression.progress.record_journey("trail", units)

func _recovered(amount: float) -> void:
	if not enabled or progression.combat.replica_view: return
	_healed += maxf(0.0, amount)
	if _healed >= 10.0:
		var units := floori(_healed)
		_healed -= units
		progression.progress.record_journey("care", units)

func _milestones() -> void:
	var journey := progression.progress.journey
	for index in JourneyPractice.TRACKS.size():
		var track := JourneyPractice.TRACKS[index]
		var rank := journey.rank(track)
		if rank > _ranks[index] and progression.hud != null:
			progression.hud.announce("%s %d / A little stronger through the life you share." % [JourneyPractice.NAMES[track], rank])
		_ranks[index] = rank

static func configure_healing(member: CoopActor) -> void:
	if member.healing == null:
		member.healing = PlayerHealing.new()
		member.healing.equipment = member.character_equipment
		member.healing.health = member.health
		member.healing.vitals = member.combat.vitals
		member.healing.eaten.connect(func(_n: String, amount: float) -> void: CombatEffects.burst(member, member.actor.global_position, "+%d HP (gradual)" % int(amount), Color("c8efa0")))
	member.progression.care.healing = member.healing
