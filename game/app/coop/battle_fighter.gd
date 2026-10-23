class_name BattleFighter
extends Node3D
## Adventure combat and temporary equipment for one equal-stat survivor.
signal gear_refreshed

var actor: Player
var combat: PlayerCombat
var health: Damageable
var loadout: ActorLoadout
var _gear: Array = []
var cloud_sequence: int = 0
var cloud_at := Vector3.ZERO

func _ready() -> void:
	combat = PlayerCombat.new()
	combat.actor = actor
	add_child(combat)
	health = Damageable.new()
	health.body = actor
	health.maximum = 100
	health.headshot_height = 0.78
	health.position.y = 0.55
	actor.add_child(health)
	health.set_physics_process(false)
	combat.owner_health = health
	combat.gun.owner_health = health
	combat.sotjet.flow.owner_health = health
	health.guard_payment = _pay_guard
	health.projectile_guard = _reflection
	health.hit.connect(ActorMeleeImpact.receive.bind(actor, combat, health))
	actor.super_dashed.connect(_cloud)
	health.attack_confirmed.connect(combat.vitals.confirmed_hit)
	ActorWeaponHands.connect_visuals(actor.visuals, combat)
	ActorCombatMotion.configure(actor, combat)
	actor.motor.spend_stamina = combat.vitals.spend
	loadout = BattleLoadout.new()
	loadout.combat = combat
	loadout.inventory = PlayerInventory.new()
	loadout.equipment = CharacterEquipment.new()
	add_child(loadout)

func equip(row: Array) -> void:
	var selected := int(row[18])
	if selected not in [1, 2] or int(row[21 + selected]) != int(row[10]): selected = 1 if int(row[10]) == int(row[22]) else 2
	var desired := [int(row[22]), int(row[23]), int(row[10]), selected]
	if desired == _gear: return
	_gear = desired
	for i in 2:
		var kind := int(row[22 + i])
		var current := loadout.equipment.get_slot("combat_%d" % (i + 1))
		if BattleItems.weapon_kind(current) != kind:
			loadout.equipment.set_slot("combat_%d" % (i + 1), ItemStack.new(BattleItems.make(kind), 1) if kind > 0 else null)
	loadout.active_slot = selected
	loadout.refresh(false)
	gear_refreshed.emit()

func step(command: PlayerCommand, delta: float) -> void:
	combat.vitals.step(delta)
	if command.cancel_actions:
		combat.interrupt()
		command.attack_held = false
		command.guard_held = false
	ActorMeleeImpact.prepare(actor, command)
	var fists := not combat.equipment.melee_selected() and not combat.ranged_selected()
	combat.equipment.step(command.aim, command.guard_held, command.punch_held or (command.attack_held and fists), false, false, 0, delta, -1, command.punch_pressed or (command.attack_pressed and fists))
	combat.step(command.aim, command.attack_held, delta, command.move if not command.face_aim else Vector2.ZERO, not actor.is_on_floor(), command.guard_held)
	combat.gun.step(command.attack_held and not command.reload_held, command.guard_held, command.aim, command.aim_point, delta, command.reload_pressed)
	combat.sotjet.step(command.attack_held, command.guard_held, command.aim, command.aim_point, delta)
	combat.bow.step(command.attack_held, command.guard_held, command.aim, command.aim_point, delta)
	actor.visuals.attack_facing = combat.attack_aim if combat.active or combat.claws.busy() else (command.aim if command.attack_held or command.guard_held or combat.equipment._punch_time > 0 else Vector2.ZERO)
	if not command.move.is_zero_approx() and not command.attack_held and not command.guard_held:
		for view in [combat.gun.visual, combat.sotjet.visual, combat.bow.visual]: view.facing = command.move

func authority(enabled: bool) -> void:
	combat.replica_view = not enabled
	combat.sotjet._replica = not enabled
	combat.sotjet.flow.authoritative = enabled

func clear_flights() -> void:
	combat.bow.clear_flights()
	combat.sotjet.flow.clear()
	for child in get_children():
		if child is FartCloud:
			child.set_physics_process(false)
			child.queue_free()
	for child in combat.gun.get_children():
		if child is SoyProjectile:
			child.set_physics_process(false)
			child.queue_free()

func _reflection(incoming: Vector3, point: Vector3, confirmed: bool) -> Vector3:
	if actor.motor.is_dashing or combat.claws.dashing: return Vector3.ZERO
	return combat.equipment.reflection_normal(incoming, point, confirmed)

func _pay_guard(amount: float) -> bool:
	var upgraded := combat.equipment.weapon_enhanced and combat.equipment.melee_selected()
	return combat.vitals.spend(amount * (BattleWeaponUpgrade.REFLECTION_COST if upgraded else 1.0))

func _cloud(at: Vector3) -> void:
	if combat.replica_view: return
	cloud_sequence += 1
	cloud_at = at
	FartCloud.spawn(self, at, combat.targets, health)
