class_name CoopEncounters
extends Node
## Assigns enemies and loot to actual party actors before their physics steps.

var game: Node3D
var party: Dictionary[String, CoopActor] = {}
var duel: CoopDuel

func _ready() -> void:
	process_physics_priority = -10
	game.encounters.experience_awarded.connect(_award_experience)
	game.encounters.party_hurt = _hurt
	game.encounters.party_collect = _collect

func _physics_process(_delta: float) -> void:
	for mob: TrainingMob in game.encounters.mob_nodes:
		if mob._windup <= 0 or not is_instance_valid(mob.quarry):
			mob.quarry = _nearest(mob.global_position, true)
	for bean: SoybeanPickup in game.encounters.pickups.values():
		if not bean._attracted or not is_instance_valid(bean.collector):
			bean.collector = _nearest(bean.global_position, false)

func _nearest(at: Vector3, outside_village: bool) -> Player:
	var nearest: Player
	var distance := INF
	for member: CoopActor in party.values():
		var actor := member.actor
		if outside_village and game.encounters.protected_area.has_point(Vector2(actor.position.x, actor.position.z)): continue
		var next := at.distance_squared_to(actor.global_position)
		if next < distance:
			distance = next
			nearest = actor
	return nearest

func _hurt(actor: Node3D, amount: float, source: Vector3, kind: Damageable.HitKind = Damageable.HitKind.SLIME) -> void:
	for member: CoopActor in party.values():
		if member.actor == actor: member.hurt(amount, source, kind)

func _collect(actor: Node3D, bean: SoybeanPickup) -> bool:
	for member: CoopActor in party.values():
		if member.actor != actor: continue
		if member.inventory == null: return false
		var requested := bean.count
		var remaining := member.inventory.add_item(InventoryItem.create_edamame(), requested)
		if remaining == requested: return false
		var collected := requested - remaining
		bean.count = remaining
		game.encounters.beans += collected
		CombatEffects.collect(self, actor.global_position, collected)
		game.encounters.progress_changed.emit(game.encounters.beans, game.encounters.mobs, game.encounters.props)
		return true
	return false

func _award_experience(amount: int) -> void:
	for key: String in party:
		if duel != null and duel.is_participant(key): continue
		party[key].progression.progress.award_experience(amount)
