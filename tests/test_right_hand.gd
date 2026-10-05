extends SceneTree
## Anatomical handedness through camera orbits, mirrored atlases and equipment.
var failures: int = 0
var stage: Node3D
var camera: Camera3D
var sprite: FufuVisuals
var combat: PlayerCombat
var hand := Vector3.ZERO
var plane := Basis.IDENTITY
var front: bool = false

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)

func _capture(at: Vector3, basis: Basis, _outward: float, near_side: bool) -> void:
	hand = at
	plane = basis
	front = near_side

func _run() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	camera = Camera3D.new()
	stage.add_child(camera)
	sprite = FufuVisuals.new()
	stage.add_child(sprite)
	combat = PlayerCombat.new()
	combat.actor = stage
	stage.add_child(combat)
	ActorWeaponHands.connect_visuals(sprite, combat)
	sprite.hand_presented.connect(_capture)
	combat.gun.visual.visible = true
	combat.sotjet.visual.visible = true
	for yaw in [0.0, 0.7, 1.9, PI, 4.6]:
		for tilt in [0.1, 0.55, 1.1]:
			camera.position = Vector3(sin(yaw), tan(tilt), cos(yaw)) * 6.0
			camera.look_at(Vector3.ZERO)
			for outfit in ["", "bright_leaf", "dark_leaf"]:
				sprite.set_worn_set(outfit, false)
				for facing in 8:
					for state in ["idle", "walk", "jump", "charge"]:
						for phase in 4:
							_pose(facing, state, phase)
							var local := plane.inverse() * (hand - sprite.global_position)
							check(front == (facing in [0, 1, 2, 7]), "near/far side keeps anatomical right through camera orbit")
							if facing in [1, 2, 3]: check(local.x < 0, "front right arm projects to screen left: %s/%s/%d" % [outfit, state, facing])
							if facing in [5, 6, 7]: check(local.x > 0, "rear right arm projects to screen right: %s/%s/%d" % [outfit, state, facing])
							_check_grips()
	_check_jump_phases()
	_check_replicas()
	_check_cut_and_guard()
	await _first_person()
	stage.queue_free()
	await process_frame
	print("Right-hand presentation: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _pose(facing: int, state: String, phase: int) -> void:
	var relative := Vector2.from_angle(facing * PI / 4)
	var back := Vector3(camera.global_basis.z.x, 0, camera.global_basis.z.z).normalized()
	var world := camera.global_basis.x * relative.x + back * relative.y
	var command := PlayerCommand.new()
	command.aim = Vector2(world.x, world.z)
	command.move = command.aim if state == "walk" else Vector2.ZERO
	sprite.jump_animation.reset()
	sprite.anim_timer = phase
	sprite.scale = Vector3(0.85, 1.2, 1)
	sprite.present(command, world * 4.8 + Vector3.UP * (4.0 if state == "jump" else 0.0), state != "jump", false, 0.0, 0.5 if state == "charge" else 0.0)
	check(int(sprite.current_facing) == facing, "camera-relative character facing")
	combat.gun.visual.facing = command.aim
	combat.sotjet.visual.facing = command.aim

func _check_grips() -> void:
	var pose := SwordGeometry.pose(Vector3.ZERO, Vector2.DOWN, -1, combat.tuning)
	for id in ["knife", "nori_katana", "edamame_sword"]:
		combat.sword.set_nori(id == "nori_katana")
		combat.sword.set_pod(id == "edamame_sword")
		combat.sword.present(pose, Vector2.DOWN, 0, false, 1.0)
		_aligned(combat.sword.model_grip_position(), "blade " + id)
	combat.staff.present(pose, 0, false, 1.0)
	_aligned(combat.staff.model_grip_position(), "staff")
	combat.sotjet.visual.refresh()
	_aligned(combat.sotjet.visual.model_grip_position(), "Soyjet")
	combat.gun.visual.reload_remaining = 0
	combat.gun.visual.kick = 0
	combat.gun.visual.refresh()
	_aligned(combat.gun.visual.global_position, "soybean gun")
	for weapon in [combat.sword, combat.staff, combat.gun.visual, combat.sotjet.visual]:
		check(weapon.grip._has_wrist and weapon.grip.visible, "cosmetic gripping hand attached")

func _aligned(grip: Vector3, label: String) -> void:
	var expected := hand + plane.z * (0.035 if front else -0.035)
	check(grip.distance_to(expected) < 0.001, label + " calibrated grip follows right wrist")

func _check_jump_phases() -> void:
	for outfit in ["", "bright_leaf", "dark_leaf"]:
		sprite.set_worn_set(outfit, false)
		for facing in 8:
			for phase in 10:
				_pose(facing, "jump", 0)
				sprite.jump_animation.frame = phase
				if outfit.is_empty(): sprite.jump_animation.apply(sprite, facing)
				else: sprite.worn_appearance.apply_jump(sprite, outfit, facing, phase)
				sprite._present_hand()
				var local := plane.inverse() * (hand - sprite.global_position)
				if facing in [1, 2, 3]: check(local.x < 0, "right arm stays left of body throughout front jump phases")
				if facing in [5, 6, 7]: check(local.x > 0, "right arm stays right of body throughout rear jump phases")
				_check_grips()

func _check_replicas() -> void:
	var replica := PlayerCombat.new()
	replica.actor = stage
	stage.add_child(replica)
	ActorWeaponHands.connect_visuals(sprite, replica)
	for outfit in ["", "bright_leaf", "dark_leaf"]:
		sprite.set_worn_set(outfit, false)
		for facing in 8:
			_pose(facing, "idle", 0)
			combat.equipment.staff_owned = true
			combat.equipment.staff_selected = true
			combat.equipment.knife_selected = false
			combat.gun.selected = false
			combat.sotjet.selected = false
			combat.active = false
			var state := CombatState.capture(combat)
			CombatState.present(replica, state, Vector2.DOWN)
			_aligned(replica.staff.model_grip_position(), "replicated staff")
			check(replica.staff.grip._material.get_shader_parameter("tint").is_equal_approx(FufuRightHand.tint(outfit)), "replica glove matches outfit")
	replica.free()

func _check_cut_and_guard() -> void:
	for facing in 8:
		_pose(facing, "idle", 0)
		for progress in [0.3, 0.5, 0.7]:
			var pose := SwordGeometry.pose(Vector3.ZERO, Vector2.from_angle(facing * PI / 4), progress, combat.tuning)
			combat.sword.present(pose, Vector2.DOWN, 0, true, 1.0)
			check(combat.sword._model_root.global_transform.is_equal_approx(pose), "cut still matches physical hitbox")
			check(combat.sword.grip.global_position.distance_to(combat.sword.model_grip_position()) < 0.001, "swing palm stays on handle")
			check(combat.sword.grip._wrist.is_equal_approx(hand), "swing arm originates at anatomical right wrist")
			var arm := combat.sword.grip._arm
			if arm.visible:
				check(arm.to_global(Vector3(0, 0.5, 0)).distance_to(combat.sword.model_grip_position()) < 0.001, "forearm ends at moving handle")
				check(arm.to_global(Vector3(0, -0.5, 0)).distance_to(hand + plane.z * (0.035 if front else -0.035)) < 0.001, "forearm starts at right wrist")
		var guard := SwordGeometry.guard_pose(Vector3.ZERO, Vector2.DOWN, combat.tuning)
		combat.sword.present(guard, Vector2.DOWN, 0, false, 0)
		check(combat.sword.grip.global_position.distance_to(combat.sword.model_grip_position()) < 0.001, "guard retains right grip")

func _first_person() -> void:
	var actor := CharacterBody3D.new()
	stage.add_child(actor)
	var overlay := FirstPersonWeapon.new()
	overlay.actor = actor
	overlay.combat = combat
	root.add_child(overlay)
	for id in ["knife", "nori_katana", "edamame_sword", "sproutwood_staff", "soy_gun", "sotjet"]:
		combat.equipment.knife_selected = id in ["knife", "nori_katana", "edamame_sword"]
		combat.equipment.knife_owned = true
		combat.equipment.nori_selected = id == "nori_katana"
		combat.equipment.pod_selected = id == "edamame_sword"
		combat.equipment.staff_owned = true
		combat.equipment.staff_selected = id == "sproutwood_staff"
		combat.gun.selected = id == "soy_gun"
		combat.sotjet.selected = id == "sotjet"
		for lowering in [0.0, 0.5, 1.0]:
			for reload_time in [0.0, 1.0, 2.0]:
				overlay.run_lowering = lowering
				combat.gun.reload_remaining = reload_time
				overlay._process(0.016)
				var contact: Vector3
				if id in ["knife", "nori_katana", "edamame_sword"]: contact = overlay._melee_model.to_global(WeaponModelCatalog.GRIPS[id])
				elif id == "sproutwood_staff": contact = overlay._staff.model_grip_position()
				elif id == "sotjet": contact = overlay._jet.model_grip_position()
				else: contact = overlay._gun.to_global(Vector3(0, -SoyGunVisual.REAR_REGIONS[0].size.y * 0.25, 0) * overlay._gun.pixel_size)
				check(overlay._hands[0].global_position.distance_to(contact) < 0.001, "first-person right palm stays on " + id + " grip")
				var arm := overlay._arms._arms[0]
				check(arm.to_global(Vector3(0, 0.5, 0)).distance_to(contact) < 0.001, "first-person forearm ends at palm")
				check(arm.to_global(Vector3(0, -0.5, 0)).distance_to(Vector3(0.55, -0.70, -0.7)) < 0.001, "primary arm always comes from camera right")
				if id == "sproutwood_staff": check(not overlay._hands[1].visible, "staff keeps primary right hand instead of fist fallback")
	overlay.queue_free()
	await process_frame
