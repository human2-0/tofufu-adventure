extends SceneTree
## Fast actual-render fixture for cuff registration, forearm seams and paw poses.

const OUT := "res://.codex/visualizations/2026/10/16/paws-alternating/"
var actor: Player
var combat: PlayerCombat
var view: FirstPersonWeapon

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1400, 900)
	root.content_scale_size = root.size
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("344943")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	stage.add_child(environment)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.65
	stage.add_child(camera)
	camera.position = Vector3(0, 1.2, 4)
	camera.look_at(Vector3.UP * 0.6)
	actor = load("res://game/player/player.tscn").instantiate()
	stage.add_child(actor)
	actor.set_physics_process(false)
	combat = PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	combat.equipment.knife_selected = false
	combat.gun.selected = false
	combat.sotjet.selected = false
	combat.claws.selected = true
	combat.gun.visual.hide()
	combat.sotjet.visual.hide()
	combat.sword.hide()
	combat.staff.hide()
	var worn := ActorBengalPawsView.new()
	worn.combat = combat
	worn.sprite = actor.visuals
	stage.add_child(worn)
	var command := PlayerCommand.new()
	for index in 8:
		command.aim = Vector2(sin(index * PI / 4), cos(index * PI / 4))
		combat.equipment.facing = command.aim
		actor.visuals.attack_facing = command.aim
		actor.visuals.present(command, Vector3.ZERO, true, false, 0.016)
		await capture("worn-%d" % index)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	view = FirstPersonWeapon.new()
	view.actor = actor
	view.combat = combat
	layer.add_child(view)
	actor.hide()
	worn.set_process(false)
	worn.hide()
	await capture("first-person-idle")
	combat.claws.charging = true
	combat.claws.charge = 1.6
	await capture("first-person-charge")
	combat.claws.cancel()
	combat.equipment._punch_time = BengalClaws.CADENCE * 0.5
	combat.equipment.punch_sequence = 1
	await capture("first-person-right")
	combat.equipment.punch_sequence = 2
	await capture("first-person-left")
	combat.equipment._punch_time = 0
	combat.claws.dashing = true
	await capture("first-person-dash")
	combat.claws.dashing = false
	combat.claws.sequence = 1
	view._paws._finisher_sequence = 1
	view._paws._finisher = 0.21
	view._paws.set_process(false)
	await capture("first-person-double-scratch")
	stage.queue_free()
	layer.queue_free()
	await process_frame
	quit()

func capture(label: String) -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + label + ".png")
