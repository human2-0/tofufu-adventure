class_name DungeonProductionPresentation
extends RefCounted
## Translates production and actors to world-only cosmetic values.

static func step(dungeon: TofuDungeon, delta: float) -> void:
	if not dungeon.enabled: dungeon.puzzle_clock += delta
	if dungeon.factory != null and dungeon.game.shooting_view != null:
		dungeon.factory.set_cutaway(not dungeon.game.shooting_view.first_person)

static func present(dungeon: TofuDungeon) -> void:
	if not dungeon.factory.interior_built: return
	DungeonStashes.present(dungeon)
	for prop: Node3D in dungeon.factory._bags: prop.visible = false
	for display: FactoryStationDisplay in dungeon.factory._displays: display.visible = false
	for label: Label3D in dungeon.factory._process_labels: label.visible = false
	var positions: Dictionary = {}
	for actor: Node3D in dungeon._actors_inside():
		var player := actor as Player
		var facing: Vector2 = Vector2.from_angle(int(player.visuals.current_facing) * PI / 4.0)
		var at: Vector3 = player.global_position if DisplayServer.get_name() == "headless" else player.presentation.ground_position
		positions[DungeonMembership.actor_id(dungeon, player)] = {"position": at, "facing": facing, "moving": Vector2(player.velocity.x, player.velocity.z).length() > 0.2}
	var press: TofuPressRules = dungeon.puzzle.press
	var elapsed: float = maxf(0.0, dungeon.puzzle_clock - press.started_at) if press.started_at >= 0.0 else 0.0
	FactoryProductionVisuals.present_factory(dungeon.factory, dungeon.puzzle.capture(true), positions,
		{"active_sample": press.active_sample, "elapsed": elapsed, "gauge": press.gauge(dungeon.puzzle_clock)})
