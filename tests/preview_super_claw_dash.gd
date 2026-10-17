extends SceneTree
## Actual charged input and collision-resolved movement after arena cleanup.

const OUT := "res://.codex/visualizations/2026/10/17/super-claw-fix/"
var game: AdventureGame

func _initialize() -> void:
	call_deferred("_run")

func ticks(count: int) -> void:
	for index in count:
		await physics_frame
		await process_frame

func _run() -> void:
	Engine.max_physics_steps_per_frame = 1
	root.size = Vector2i(1600, 900)
	root.content_scale_size = root.size
	game = load("res://game/app/adventure/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.solo_arena.enabled = false
	game.shooting_view.local_input.enabled = false
	game.weather.set_physics_process(false)
	game.hud.hide()
	game.chat.view.hide()
	for mob in game.encounters.mob_nodes:
		mob.set_physics_process(false)
		mob.target.set_physics_process(false)
	var cat := game.encounters.mob_nodes[59] as BengalMonster
	game.progression.progress.award_experience(CharacterProgress.threshold(15, true))
	game.character_equipment.set_slot("combat_1", ItemStack.new(BengalPawsItem.create(), 1))
	game.loadout.select(1)
	game.combat.targets = [cat.target]
	var input := CoopTestInput.new()
	root.add_child(input)
	game.player.command_source = input
	game.player.relocate(cat.position - Vector3.BACK * 4.5)
	SoloArenaFighter.stop_motion(game.player)
	game.camera.set_physics_process(false)
	game.camera.set_process(false)
	game.camera.position = cat.position + Vector3(6, 5, 5)
	game.camera.look_at(cat.position - Vector3.BACK * 1.5 + Vector3.UP * 0.6)
	await ticks(5)
	input.guard = true
	for index in 90:
		_aim(input, cat)
		await ticks(1)
	await capture("charging")
	for index in 50:
		_aim(input, cat)
		if game.combat.claws.dashing: break
		await ticks(1)
	assert(game.combat.claws.dashing, "Charged skill must start its dash")
	var start := game.player.position
	await ticks(4)
	await capture("dashing")
	await ticks(28)
	await capture("rift-finisher")
	var travel := Vector2(game.player.position.x - start.x, game.player.position.z - start.z).length()
	assert(travel > 0.5 and game.combat.claws.sequence == 1, "Dash must move before its finisher")
	print("Super Claw after arena reset: ", travel, " metres; finisher ", game.combat.claws.sequence)
	game.queue_free()
	await process_frame
	quit()

func _aim(input: CoopTestInput, cat: BengalMonster) -> void:
	var offset := cat.position - game.player.position
	input.aim = Vector2(offset.x, offset.z).normalized()
	input.aim_point = cat.target.global_position

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + label + ".png")
