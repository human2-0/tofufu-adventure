extends SceneTree
## Ballistics, continuous damage, cover, reservoir, replica safety and persistence.

var failures: int = 0
var stage: Node3D
var actor: Player
var combat: PlayerCombat
var target: PracticeDummy

func _initialize() -> void: call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func ticks(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func pour(count: int) -> void:
	for i in count:
		combat.sotjet.step(true, true, Vector2.UP, Vector3(0, 0.78, -40), 1.0 / 60.0)
		await ticks(1)

func _run() -> void:
	var parcel := SotjetParcel.new()
	parcel.position = Vector3(0, 10, 0)
	parcel.velocity = Vector3(24, 0, 0)
	for i in 30: parcel.advance(1.0 / 60.0, 12.0)
	check(parcel.position.is_equal_approx(Vector3(12, 8.5, 0)), "milk follows x=v*t and y=-g*t²/2")
	stage = Node3D.new()
	root.add_child(stage)
	actor = load("res://game/player/player.tscn").instantiate()
	stage.add_child(actor)
	actor.set_physics_process(false)
	combat = PlayerCombat.new()
	combat.actor = actor
	stage.add_child(combat)
	target = PracticeDummy.new()
	stage.add_child(target)
	target.position = Vector3(0, 0, -5)
	combat.targets.append(target.target)
	combat.sotjet.flow.targets = combat.targets
	await ticks(3)
	combat.equipment.step(Vector2.UP, false, false, false, false, 4, 0.016)
	check(combat.sotjet.selected and not combat.gun.selected and combat.equipment.suppress_slash(), "slot 4 exclusively equips Sotjet")
	await pour(30)
	check(target.target.current < target.target.maximum and target.target.current > 160, "continuous milk damages with bounded per-target cadence")
	check(combat.sotjet.flow.get_children().any(func(child: Node) -> bool: return child is Label3D and child.text.begins_with("-")), "confirmed milk hits show floating damage amounts")
	check(combat.sotjet.milk < 91 and combat.sotjet.milk > 89, "half second consumes ten milk")
	check(combat.sotjet.flow.parcels.size() <= 96, "fluid parcel count bounded")
	var before := combat.sotjet.milk
	combat.sotjet.step(false, false, Vector2.UP, Vector3.ZERO, 0.2)
	check(is_equal_approx(before, combat.sotjet.milk), "refill waits after firing")
	for i in 120: combat.sotjet.step(false, false, Vector2.UP, Vector3.ZERO, 1.0 / 60.0)
	check(is_equal_approx(combat.sotjet.milk, 100), "released trigger refills reservoir")
	combat.sotjet.milk = 0
	combat.sotjet.step(true, true, Vector2.UP, Vector3.ZERO, 0.016)
	check(not combat.sotjet.firing and combat.sotjet.milk == 0, "empty reservoir cannot fire or refill while trigger held")
	combat.sotjet.milk = 100
	combat.sotjet.reset()
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 3, 0.06)
	shape.shape = box
	wall.add_child(shape)
	stage.add_child(wall)
	wall.position = Vector3(0, 0.5, -2)
	target.target.restore()
	target.target.invulnerability = 0
	await ticks(3)
	await pour(35)
	await ticks(15)
	check(target.target.current == target.target.maximum, "thin wall absorbs milk before target")
	wall.position.z = -0.25
	combat.sotjet.reset()
	await ticks(2)
	await pour(2)
	check(combat.sotjet.flow.parcels.is_empty(), "actor-to-muzzle cover cannot be bypassed")
	wall.queue_free()
	await ticks(2)
	combat.sotjet.use_replica()
	var snapshot := CombatState.capture(combat)
	snapshot.jet_firing = true
	snapshot.jet_sequence += 10
	snapshot.jet_origin = [0, 0.78, -0.5]
	snapshot.jet_velocity = [0, 0, -24]
	combat.sotjet.present(snapshot, Vector2.UP)
	await ticks(40)
	check(target.target.current == target.target.maximum, "replica milk cannot apply damage")
	check(not combat.sotjet.flow.visual.pouring, "replica stream stops on stale snapshots")
	check(ExplorationProtocol.combat(snapshot), "Sotjet snapshot validates")
	snapshot.milk = -1
	check(not ExplorationProtocol.combat(snapshot), "negative milk rejected")
	snapshot.milk = 100
	snapshot.gun = true
	check(not ExplorationProtocol.combat(snapshot), "simultaneous guns rejected")
	var command := PlayerCommand.new()
	command.weapon_slot = 4
	check(ExplorationProtocol.valid_input(CoopValues.input(command, 1, 0)), "slot 4 survives input schema")
	command.weapon_slot = 5
	check(not ExplorationProtocol.valid_input(CoopValues.input(command, 1, 0)), "undefined slot rejected")
	Input.action_press("sotjet_slot")
	check(actor.command_source.sample(Vector3.ZERO).weapon_slot == 4, "keyboard action maps to Sotjet")
	Input.action_release("sotjet_slot")
	stage.free()
	await _saves()
	print("Sotjet: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _saves() -> void:
	var game: Node3D = load("res://game/app/main.tscn").instantiate()
	game.play_opening = false
	root.add_child(game)
	game.player.set_physics_process(false)
	game.combat.equipment.step(Vector2.UP, false, false, false, false, 4, 0.016)
	game.combat.sotjet.milk = 37
	var data := AdventureSnapshot.capture(game, "Milk", 0)
	var store := SaveStore.new()
	check(store.valid(data), "solo Sotjet save validates")
	game.combat.sotjet.selected = false
	AdventureSnapshot.restore(game, data)
	check(game.combat.sotjet.selected and game.combat.sotjet.milk == 37, "solo selection and milk restore")
	var state := CombatState.capture(game.combat)
	game.combat.sotjet.milk = 99
	CombatState.restore(game.combat, state)
	check(game.combat.sotjet.selected and game.combat.sotjet.milk == 37 and not game.combat.sotjet.firing, "co-op save restores reservoir without firing")
	data.erase("sotjet_selected")
	data.erase("soymilk")
	AdventureSnapshot.restore(game, data)
	check(not game.combat.sotjet.selected and game.combat.sotjet.milk == 100, "legacy saves default safely")
	game.queue_free()
	await process_frame
