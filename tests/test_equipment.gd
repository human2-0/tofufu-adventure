extends SceneTree
## Exercise equipment through the real scene and incoming enemy damage path.
var failures: int = 0
var scene: Node3D

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	scene = load("res://game/app/adventure/main.tscn").instantiate()
	scene.play_opening = false
	root.add_child(scene)
	scene.player.set_physics_process(false)
	for child in scene.encounters.get_children():
		if child is TrainingMob:
			child.set_physics_process(false)
	scene.player.position = Vector3.ZERO
	await physics_frame
	var combat: PlayerCombat = scene.combat
	var equipment: PlayerEquipment = combat.equipment
	equipment.step(Vector2.UP, true, false, false, false, 0, 0.016)
	scene.encounters._hurt_player(12.0, Vector3(0, 0, -1))
	check(scene.health.current == 100.0, "front knife guard prevents real incoming damage")
	check(equipment.blocks(Vector3(0.7, 0, -0.7)), "45 degree attack is inside guard")
	check(not equipment.blocks(Vector3(1, 0, 0)), "side attack bypasses guard")
	scene.encounters._hurt_player(12.0, Vector3(0, 0, 1))
	check(scene.health.current == 88.0, "rear attack damages guarding player")
	combat.rules.step(true, 0.5)
	equipment.step(Vector2.UP, true, false, false, false, 0, 0.016)
	combat.step(Vector2.UP, false, 0.016)
	check(not combat.active and combat.rules.charge == 0.0, "guard cancels charge without releasing a slash")
	equipment.step(Vector2.UP, false, false, false, false, 0, 0.016)
	combat.strike(Vector2.UP, 0.0)
	equipment.step(Vector2.UP, true, false, true, false, 0, 0.016)
	check(not equipment.guarding and equipment.knife_owned, "committed slash cannot guard or drop mid-cut")
	combat.reset()
	equipment.step(Vector2.UP, true, false, true, false, 0, 0.016)
	check(not equipment.knife_owned and not equipment.guarding and not combat.sword.visible, "drop empties knife slot and disables defence")
	check(is_instance_valid(equipment.dropped), "drop creates a recoverable world knife")
	scene.player.position = Vector3(5, 0, 0)
	equipment.step(Vector2.UP, false, false, false, true, 0, 0.016)
	check(not equipment.knife_owned, "distant knife cannot be collected")
	scene.player.position = Vector3.ZERO
	equipment.step(Vector2.UP, false, false, false, true, 0, 0.016)
	check(equipment.knife_owned and equipment.knife_selected, "nearby knife can be recovered and equipped")
	var mob := TrainingMob.new()
	mob.position = Vector3(0, 0, -1)
	scene.add_child(mob)
	mob.set_physics_process(false)
	combat.targets = [mob.target]
	await physics_frame
	equipment.step(Vector2.UP, false, true, false, false, 1, 0.4)
	check(mob.target.current == 48.0, "F punches while knife remains equipped")
	equipment.step(Vector2.UP, false, true, false, false, 0, 0.016)
	check(mob.target.current == 48.0, "punch cooldown rejects repeat hit")
	for tick in 90: equipment.step(Vector2.UP, false, true, false, false, 0, 1.0 / 60.0)
	check(mob.target.current == 48.0, "holding punch never repeats even after animation and cooldown")
	equipment.step(Vector2.UP, false, false, false, false, 0, 0.01)
	var command := PlayerCommand.new()
	command.aim = Vector2.UP
	command.attack_held = true
	command.attack_pressed = true
	scene.character_equipment.set_slot("combat_2", null)
	command.weapon_slot = 2
	scene._on_command(command, 0.4)
	command.attack_pressed = false
	scene._on_command(command, 0.016)
	check(mob.target.current == 36.0 and not equipment.guarding, "fist slot attacks without knife defence")
	for tick in 90: scene._on_command(command, 1.0 / 60.0)
	check(mob.target.current == 36.0, "holding LMB in fist slot cannot autoattack")
	command.attack_held = false
	scene._on_command(command, 0.01)
	command.attack_held = true
	command.attack_pressed = true
	scene._on_command(command, 0.04)
	check(mob.target.current == 24.0, "fresh click attacks immediately within previous punch animation")
	command.attack_pressed = false
	equipment.step(Vector2.UP, false, false, false, false, 0, 0.04)
	mob.position.y = 3.0
	equipment.step(Vector2.UP, false, true, false, false, 0, 0.4)
	check(mob.target.current == 24.0, "punch does not hit enemies above its reach")
	equipment.step(Vector2.UP, false, false, false, false, 0, 0.04)
	mob.position.y = 0.0
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.8, 1.5, 0.1)
	collider.shape = shape
	wall.add_child(collider)
	wall.position = Vector3(0, 0.6, -0.5)
	scene.add_child(wall)
	await physics_frame
	equipment.step(Vector2.UP, false, true, false, false, 0, 0.4)
	check(mob.target.current == 24.0, "solid wall occludes fist damage")
	await _strike_presentations()
	scene.queue_free()
	await process_frame
	print("Equipment and guard: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _strike_presentations() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var host := PlayerCombat.new()
	host.actor = stage
	stage.add_child(host)
	var peer := PlayerCombat.new()
	peer.actor = stage
	peer.replica_view = true
	stage.add_child(peer)
	var host_loadout := _strike_loadout(stage, host, false)
	var peer_loadout := _strike_loadout(stage, peer, true)
	var target := Damageable.new()
	stage.add_child(target)
	peer.targets = [target]
	var health := target.current
	for outfit in PunchImpact.OUTFITS:
		for slot in CharacterEquipment.APPAREL_SLOTS:
			host_loadout.equipment.set_slot(slot, null if outfit.is_empty() else ItemStack.new(InventoryItem.apparel(outfit + "_" + slot), 1))
		var saved: Dictionary = JSON.parse_string(JSON.stringify(host_loadout.equipment.capture()))
		peer_loadout.equipment.restore(saved)
		check(host.equipment.punch_outfit == outfit and peer.equipment.punch_outfit == outfit, "worn outfit selects matching strike art locally and after a saved equipment restore")
		peer.equipment.punch_sequence = host.equipment.punch_sequence
		var counts: Array[int] = [0, 0, 0, 0]
		for click in 8:
			host.equipment.step(Vector2.RIGHT, false, true, false, false, 0, 0.041, -1, true)
			var local_effects := _strike_effects(host.equipment)
			var local: PunchImpact = local_effects.back()
			local.set_process(false)
			counts[local.style] += 1
			var state := CombatState.capture(host)
			CombatState.present(peer, state, Vector2.UP)
			var effects := _strike_effects(peer)
			var remote: PunchImpact = effects.back()
			remote.set_process(false)
			check(local.style == remote.style and local.outfit == remote.outfit, "replica displays the same strike and armour as the authoritative click")
			check(remote.forward == Vector3.RIGHT, "replica strike follows the received punch facing instead of idle aim")
			CombatState.present(peer, state, Vector2.UP)
			check(_strike_effects(peer).size() == effects.size(), "repeated snapshots do not replay a strike")
			local._process(PunchImpact.LIFETIME)
			remote._process(PunchImpact.LIFETIME)
			check(local.is_queued_for_deletion() and remote.is_queued_for_deletion(), "fast strike cutouts retire after their bounded lifetime")
		check(counts == [2, 2, 2, 2], "eight rapid clicks show every strike twice")
		peer_loadout.equipment.set_slot("boots", null)
		check(peer.equipment.punch_outfit.is_empty(), "removing an armour piece immediately restores base strike art")
	check(target.current == health, "cosmetic replica strikes cannot damage targets")
	var before := _strike_effects(host.equipment).size()
	host.claws.selected = true
	host.equipment.step(Vector2.RIGHT, false, true, false, false, 0, 0.5, -1, true)
	check(_strike_effects(host.equipment).size() == before, "Bengal Paws retain their own claw effects")
	stage.queue_free()
	await process_frame

func _strike_loadout(stage: Node, combat: PlayerCombat, replica: bool) -> ActorLoadout:
	var loadout := ActorLoadout.new()
	loadout.combat = combat
	loadout.equipment = CharacterEquipment.new()
	loadout.equipment.wearer_level = 20
	loadout.inventory = PlayerInventory.new()
	loadout.replica = replica
	stage.add_child(loadout)
	return loadout

func _strike_effects(parent: Node) -> Array[Node]:
	return parent.get_children().filter(func(node: Node) -> bool: return node is PunchImpact)
