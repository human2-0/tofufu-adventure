class_name TofuDungeonReplica
extends RefCounted
## Bounded factory snapshot translation; replicas only present host-owned creatures.

static func capture(dungeon: TofuDungeon) -> Dictionary:
	var data := dungeon.state.capture()
	data.cargo = dungeon.cargo_positions()
	data.secured = dungeon.state.secured
	data.active = dungeon.state.active
	data.processing = dungeon.state.process_remaining
	data.enemies = []
	data.crates = []
	for enemy: FactoryBean in dungeon._enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			var at := enemy.position
			data.enemies.append([int(enemy.kind), at.x, at.y, at.z, enemy.target.current])
	for crate: FactoryCrate in dungeon._crates:
		if is_instance_valid(crate) and not crate.is_queued_for_deletion():
			var at := crate.position
			data.crates.append([at.x, at.y, at.z])
	return data

static func apply(dungeon: TofuDungeon, data: Dictionary) -> void:
	if bool(data.active): dungeon.factory.ensure_interior()
	if dungeon.state.stage != int(data.stage) or dungeon.state.completed != bool(data.completed):
		dungeon.state.restore(data)
		dungeon.factory.reset_gates(dungeon.state.stage)
	dungeon.state.units = int(data.get("units", 0))
	dungeon.state.secured = bool(data.get("secured", false))
	dungeon.state.coagulant_added = bool(data.get("coagulant_added", false))
	dungeon.factory.show_cargo(data.get("cargo", []))
	dungeon.factory.show_objective(dungeon.state.stage, dungeon.state.units, dungeon.state.secured or (dungeon.state.stage == 3 and not dungeon.state.coagulant_added), not data.get("cargo", []).is_empty())
	dungeon.state.active = bool(data.active)
	dungeon.state.process_remaining = float(data.processing)
	if dungeon.state.process_remaining > 0: dungeon.factory.show_processing(dungeon.state.stage, dungeon.state.process_remaining)
	dungeon.state.broken_crates = int(data.get("broken_crates", 0))
	if dungeon.state.active and not dungeon.factory.interior_built: dungeon.factory.ensure_interior()
	_sync_enemies(dungeon, data.enemies)
	_sync_crates(dungeon, data.crates)

static func _sync_enemies(dungeon: TofuDungeon, rows: Array) -> void:
	while dungeon._replica_enemies.size() > rows.size():
		dungeon._replica_enemies.pop_back().queue_free()
	for i in rows.size():
		var row: Array = rows[i]
		var enemy: FactoryBean = dungeon._replica_enemies[i] if i < dungeon._replica_enemies.size() else null
		if enemy != null and int(enemy.kind) != int(row[0]):
			enemy.queue_free()
			enemy = null
		if enemy == null:
			enemy = FactoryBean.new()
			enemy.kind = int(row[0])
			dungeon.game.world.add_child(enemy)
			enemy.set_physics_process(false)
			enemy.target.set_physics_process(false)
			enemy.collision_layer = 0
			if i < dungeon._replica_enemies.size(): dungeon._replica_enemies[i] = enemy
			else: dungeon._replica_enemies.append(enemy)
		enemy.position = Vector3(row[1], row[2], row[3])
		enemy.target.current = float(row[4])

static func _sync_crates(dungeon: TofuDungeon, rows: Array) -> void:
	while dungeon._replica_crates.size() > rows.size():
		dungeon._replica_crates.pop_back().queue_free()
	for i in rows.size():
		var row: Array = rows[i]
		var crate: FactoryCrate = dungeon._replica_crates[i] if i < dungeon._replica_crates.size() else null
		if crate == null:
			crate = FactoryCrate.new()
			dungeon.game.world.add_child(crate)
			crate.set_physics_process(false)
			crate.target.set_physics_process(false)
			crate._body.collision_layer = 0
			dungeon._replica_crates.append(crate)
		crate.position = Vector3(row[0], row[1], row[2])
