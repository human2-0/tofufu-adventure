extends SceneTree

var failures: int = 0
const DT: float = 1.0 / 60.0

func _initialize() -> void:
	_charge_rules()
	_animation_phases()
	call_deferred("_charge_visuals")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", message)

func _charge_rules() -> void:
	var tuning := PlayerTuning.new()
	var motor := PlayerMotor.new(tuning)
	var other := PlayerMotor.new(tuning)
	var command := PlayerCommand.new()
	command.jump_pressed = true
	command.jump_held = true
	motor.step(command, Vector3.ZERO, true, DT)
	command.jump_pressed = false
	for tick in 15:
		motor.step(command, Vector3.ZERO, true, DT)
	check(motor.jump_charge > 0.3 and motor.jump_charge < 0.5, "partial hold loads proportionally")
	check(other.jump_charge == 0.0, "charge is per actor")
	command.jump_held = false
	var velocity := motor.step(command, Vector3.ZERO, true, DT)
	check(velocity.y > tuning.jump_velocity and velocity.y < tuning.jump_velocity * sqrt(2.0), "partial release lies between tap and super jump")
	command.jump_pressed = true
	command.jump_held = true
	var next := motor.step(command, velocity, false, DT)
	check(next.y < velocity.y and not motor.is_charging_jump, "midair press cannot boost or double jump")
	command.jump_pressed = false
	for tick in 20:
		motor.step(command, Vector3.ZERO, false, DT)
	motor.step(command, Vector3.ZERO, true, DT)
	check(not motor.is_charging_jump, "old midair hold does not auto-load on landing")
	command.jump_pressed = true
	motor.step(command, Vector3.ZERO, true, DT)
	command.jump_pressed = false
	for tick in 20:
		motor.step(command, Vector3.ZERO, false, DT)
	check(not motor.is_charging_jump and motor.jump_charge == 0.0, "leaving the ledge cancels charge after coyote window")
	command.jump_pressed = true
	motor.step(command, Vector3.ZERO, true, DT)
	command.dash_pressed = true
	motor.step(command, Vector3.ZERO, true, DT)
	check(motor.is_dashing and not motor.is_charging_jump, "dash cancels grounded charge")

func _animation_phases() -> void:
	var animation := FufuJumpAnimation.new()
	animation.step(true, 0, true, 0, DT)
	check(animation.frame == 0, "charge uses takeoff crouch")
	animation.launch()
	animation.step(false, 12, false, INF, DT)
	check(animation.frame == 0, "launch begins with takeoff")
	animation.step(false, 10, false, INF, 0.06)
	check(animation.frame == 1, "push-off follows takeoff")
	animation.step(false, 7, false, INF, 0.1)
	check(animation.frame == 2, "ascent follows upward velocity")
	animation.step(false, 0, false, INF, DT)
	check(animation.frame == 3, "apex follows near-zero vertical velocity")
	animation.step(false, -3, false, 10, DT)
	check(animation.frame == 4, "fall starts after apex")
	animation.step(false, -8, false, 10, DT)
	check(animation.frame == 5, "long falls retain falling pose")
	animation.step(false, -8, false, 0.3, DT)
	check(animation.frame == 6, "nearby ground triggers pre-landing")
	animation.step(true, 0, false, 0, 0.071)
	check(animation.frame == 7, "impact only follows real ground contact")
	animation.step(true, 0, false, 0, 0.071)
	check(animation.frame == 8, "landing rebounds")
	animation.step(true, 0, false, 0, 0.071)
	check(animation.frame == 9, "landing settles")
	animation.step(true, 0, false, 0, DT)
	check(animation.frame == -1, "return to directional idle/walk after landing")
	animation.reset()
	animation.step(false, -7, false, 4, DT)
	check(animation.frame == 5, "walking off a ledge skips takeoff")

func _charge_visuals() -> void:
	var sprite := FufuVisuals.new()
	root.add_child(sprite)
	var command := PlayerCommand.new()
	for direction in 8:
		command.move = Vector2.from_angle(direction * PI / 4)
		command.aim = Vector2.DOWN
		for column in 6:
			sprite.anim_timer = column
			sprite.present(command, Vector3.ONE, true, false, 0, 0.5)
			check(int(sprite.current_facing) == direction, "moving charge follows travel")
			if direction in [5, 7]:
				check(sprite.texture == sprite.diagonal_texture, "rear diagonals retain true rear-diagonal art")
			else:
				var atlas := sprite.texture as AtlasTexture
				check(atlas != null and atlas.atlas == FufuChargeAnimation.SOURCE, "charge selects supplied art")
				check(sprite.flip_h == (direction in [0, 1]), "east and southeast mirror west and southwest")
				check(atlas.region.position.x > 195 if direction != 6 else atlas.region.position.x >= 187, "source direction labels are excluded")
				if direction == 2:
					check(atlas.region.position.y > 256 and atlas.region.position.y < 512, "south uses face-visible second row")
				elif direction == 6:
					check(atlas.region.position.y > 768, "north uses rear-facing bottom row")
	command.move = Vector2.RIGHT
	command.aim = Vector2.UP
	sprite.present(command, Vector3.ZERO, true, false, 0.1, 0.5)
	check(sprite.current_facing == FufuVisuals.Facing.UP and sprite.anim_timer == 0, "blocked charge faces mouse and stops cycling")
	command.attack_held = true
	command.aim = Vector2.LEFT
	sprite.present(command, Vector3.ONE, true, false, 0.1, 0.5)
	check(sprite.current_facing == FufuVisuals.Facing.LEFT and not sprite.flip_h, "focused aiming overrides movement during charge")
	sprite.show_jump()
	sprite.present(command, Vector3.UP * 12, false, false, DT)
	check(sprite.texture is AtlasTexture and sprite.texture.atlas == DirectionalJumpArt.SOURCE and not sprite._using_charge_frame, "release replaces charge walk with airborne takeoff")
	sprite.present(command, Vector3.ZERO, true, false, 0.3)
	sprite.present(command, Vector3.ZERO, true, false, 0.1)
	check(sprite.texture == sprite.idle_texture, "normal directional art returns after landing")
	for facing in 8:
		for phase in 10:
			sprite.jump_animation.frame = phase
			sprite.jump_animation.apply(sprite, facing)
			if facing == 2:
				check(sprite.texture == FufuJumpAnimation.TEXTURES[phase], "front jump keeps supplied phase art")
			else:
				check(sprite.texture is AtlasTexture and sprite.material_override != null, "missing directions use the generated atlas with keyed background")
				check(sprite.flip_h == (facing in [0,1,7]), "right jump views mirror their left counterparts")
				var bounds := (sprite.texture as AtlasTexture).region
				check(bounds.size.x > 0 and bounds.size.y > 0 and Rect2(Vector2.ZERO, DirectionalJumpArt.SOURCE.get_size()).encloses(bounds), "jump region stays inside the source")
				check(sprite.jump_animation.hand.x >= 0 and sprite.jump_animation.hand.x <= bounds.size.x, "generated jump hand remains inside its frame")
			check(sprite.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "directional jump stays camera-facing")
	sprite.queue_free()
	await process_frame
	print("Charged jump, directional loading and landing animation: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
