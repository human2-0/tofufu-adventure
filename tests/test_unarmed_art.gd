extends SceneTree
## Real attack counters, outfit restore, camera-relative body poses and priorities.

var failures: int = 0
var stage: Node3D
var camera: Camera3D
var host: PlayerCombat
var peer: PlayerCombat

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	printerr("FAIL: ", message)

func _run() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	camera = Camera3D.new()
	stage.add_child(camera)
	host = _actor(Vector3.ZERO)
	peer = _actor(Vector3(3, 0, 0))
	peer.replica_view = true
	var command := PlayerCommand.new()
	command.move = Vector2.LEFT
	for outfit in PunchImpact.OUTFITS:
		(host.actor as Player).visuals.set_worn_set(outfit, false)
		(peer.actor as Player).visuals.set_worn_set(outfit, false)
		host.equipment.punch_outfit = outfit
		peer.equipment.punch_outfit = outfit
		for yaw in [0.0, 0.85]:
			camera.position = Vector3(sin(yaw) * 6, 4, cos(yaw) * 6)
			camera.look_at(Vector3.ZERO)
			for facing in 8:
				command.aim = Vector2.from_angle(facing * PI / 4)
				for click in 4:
					host.equipment.step(command.aim, false, true, false, false, 0, 0.041, -1, true)
					var local := (host.actor as Player).visuals
					local.present(command, Vector3.LEFT * 3, true, false, 0)
					CombatState.present(peer, CombatState.capture(host), Vector2.UP)
					var remote := (peer.actor as Player).visuals
					remote.present(command, Vector3.LEFT * 3, true, false, 0)
					check(local._using_unarmed_frame and remote._using_unarmed_frame, "accepted clicks replace the whole moving actor on authority and replica")
					check(local.unarmed_art.style == remote.unarmed_art.style and local.unarmed_art.style == PunchImpact.variant(host.equipment.punch_sequence), "body, hit effect and peer use the same sequence style")
					check(local.current_facing == remote.current_facing, "body attack direction agrees through camera rotation")
					check((local.texture as AtlasTexture).atlas.resource_path.ends_with(("base" if outfit.is_empty() else outfit) + ".png"), "body contact uses the matching full outfit atlas")
					check(local.texture.get_height() * local.pixel_size < 1.6 and local.texture.get_height() * local.pixel_size > 0.8, "full-body contact retains the existing character scale")
					check(FufuRightHand.point(local).is_finite(), "new pose supplies a finite wrist attachment")
	_priorities(command)
	stage.queue_free()
	await process_frame
	print("Whole-body unarmed art: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _actor(at: Vector3) -> PlayerCombat:
	var actor := load("res://game/player/player.tscn").instantiate() as Player
	stage.add_child(actor)
	actor.position = at
	actor.set_physics_process(false)
	var combat := PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	combat.equipment.knife_owned = false
	combat.equipment.knife_selected = false
	ActorWeaponHands.connect_visuals(actor.visuals, combat)
	return combat

func _priorities(command: PlayerCommand) -> void:
	var actor := host.actor as Player
	var sprite := actor.visuals
	host.equipment._punch_time = host.tuning.punch_cooldown
	sprite.present(command, Vector3.ZERO, true, false, 0)
	check(sprite._using_unarmed_frame, "fresh hit shows the contact pose")
	host.equipment._punch_time = host.tuning.punch_cooldown - PunchImpact.LIFETIME - 0.001
	sprite.present(command, Vector3.ZERO, true, false, 0)
	check(not sprite._using_unarmed_frame, "body returns to ordinary art when the matching effect ends")
	host.equipment._punch_time = host.tuning.punch_cooldown
	sprite.present(command, Vector3.UP, false, false, 0)
	check(not sprite._using_unarmed_frame, "airborne presentation retains jump priority")
	sprite.present(command, Vector3.ZERO, true, true, 0)
	check(not sprite._using_unarmed_frame, "dash retains its own body presentation")
	sprite.present(command, Vector3.ZERO, true, false, 0, 0.5)
	check(not sprite._using_unarmed_frame, "jump charge retains its own body presentation")
	actor.transport_active = true
	sprite.present(command, Vector3.ZERO, true, false, 0)
	check(not sprite._using_unarmed_frame, "riding cannot replay a residual strike pose")
	actor.transport_active = false
	host.gun.selected = true
	sprite.present(command, Vector3.ZERO, true, false, 0)
	check(not sprite._using_unarmed_frame, "ranged equipment keeps its existing poses")
	host.gun.selected = false
	host.claws.selected = true
	sprite.present(command, Vector3.ZERO, true, false, 0)
	check(not sprite._using_unarmed_frame, "Bengal Paws keep their dedicated presentation")
	host.claws.selected = false
	host.reset()
	sprite.present(command, Vector3.ZERO, true, false, 0)
	check(not sprite._using_unarmed_frame, "reset clears transient body contacts")
