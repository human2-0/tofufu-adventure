extends SceneTree
## Walk the entire outdoor circuit and each bridge using a real player-size capsule.

class Walker extends CharacterBody3D:
	var heading := Vector2.ZERO
	func _physics_process(delta: float) -> void:
		velocity.x = heading.x * 4.5
		velocity.z = heading.y * 4.5
		velocity.y -= 40.0 * delta
		move_and_slide()

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var island := VolcanicWorld.new()
	root.add_child(island)
	var walker := Walker.new()
	walker.collision_layer = 2
	walker.collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.1
	shape.shape = capsule
	shape.position.y = 0.55
	walker.add_child(shape)
	root.add_child(walker)
	for i in 4: await physics_frame
	for crossing in VolcanicRoutes.crossings():
		var at: Vector2 = crossing.at
		var heading: Vector2 = crossing.direction
		walker.position = VolcanicTerrain.point(at - heading * 27, 0.1)
		walker.velocity = Vector3.ZERO
		walker.heading = Vector2.ZERO
		for tick in 5: await physics_frame
		var goal := at + heading * 27
		for tick in 900:
			var remaining := goal - Vector2(walker.position.x, walker.position.z)
			if remaining.length() < 1: break
			walker.heading = remaining.normalized()
			await physics_frame
		walker.heading = Vector2.ZERO
		check(Vector2(walker.position.x, walker.position.z).distance_to(at + heading * 27) < 2, "ordinary walking crosses the complete bridge and both ramps at %s; ended %s" % [at, walker.position])
		check(walker.position.y > VolcanicTerrain.WATER_LEVEL, "crossing ends on supported dry land")
	for route in [[LavaCastle.CENTER + Vector2(0, 54), LavaCastle.CENTER + Vector2(0, 25)], [VolcanicLandmarks.SITES[2] + Vector2(19, 0), VolcanicLandmarks.SITES[2] + Vector2(5, 0)]]:
		walker.position = VolcanicTerrain.point(route[0], 0.1)
		walker.velocity = Vector3.ZERO
		walker.heading = Vector2.ZERO
		for tick in 5: await physics_frame
		for tick in 650:
			var remaining: Vector2 = route[1] - Vector2(walker.position.x, walker.position.z)
			if remaining.length() < 0.7: break
			walker.heading = remaining.normalized()
			await physics_frame
		walker.heading = Vector2.ZERO
		for tick in 5: await physics_frame
		check(Vector2(walker.position.x, walker.position.z).distance_to(route[1]) < 1.2 and walker.is_on_floor(), "ordinary walking enters the castle bridge and sanctuary court, goal %s, position %s" % [route[1], walker.position])
	var space := walker.get_world_3d().direct_space_state
	var basalt := island.find_child("VolcanicBasaltCollision", true, false) as StaticBody3D
	check(basalt != null, "large batched basalt scenery retains physical obstacle collision")
	if basalt != null:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(basalt.position + Vector3.UP * 8, basalt.position, 1))
		check(not hit.is_empty() and hit.collider == basalt, "large visual columns block real world-layer physics rays")
	var grid := VolcanicGroundGrid.new()
	var crater_edge := VolcanicTerrain.point(VolcanicTerrain.VOLCANO + Vector2(8, -2), 0.05)
	check(VolcanicLava.molten(crater_edge), "the entire visible crater pool is hazardous between river channels")
	check(not VolcanicLava.molten(crater_edge + Vector3.UP * 2), "clearance above the crater surface remains safe")
	var sample := VolcanicTerrain.VOLCANO + Vector2(37.35, 22.15)
	var cached := grid.point(sample)
	var physical := _floor(space, sample)
	check(absf(cached.y - physical.y) < 0.01, "lava placement samples exact collision triangles on steep irregular slopes")
	for i in range(1, VolcanicRoutes.CIRCUIT.size()):
		var start := VolcanicRoutes.CIRCUIT[i - 1]
		var end := VolcanicRoutes.CIRCUIT[i]
		var steps := ceili(start.distance_to(end) / 2)
		for j in steps:
			var at := start.lerp(end, float(j) / steps)
			var next := start.lerp(end, float(j + 1) / steps)
			var floor_at := _floor(space, at)
			var floor_next := _floor(space, next)
			check(floor_at.y > VolcanicTerrain.WATER_LEVEL, "outdoor circuit stays dry at %s" % at)
			check(not VolcanicLava.molten(floor_at), "outdoor circuit crosses lava on bridges at %s" % at)
			var collision := KinematicCollision3D.new()
			var blocked := walker.test_move(Transform3D(Basis.IDENTITY, floor_at + Vector3.UP * 0.05), floor_next - floor_at, collision)
			check(not blocked or collision.get_normal().dot(Vector3.UP) > 0.7, "outdoor circuit has unobstructed capsule clearance at %s, normal %s" % [at, collision.get_normal() if blocked else Vector3.ZERO])
	var packet := {"position": [635.0, 4.0, 395.0], "velocity": [0, 0, 0], "aim": [0, 1], "grounded": true, "dashing": false, "charge": 0, "cooldown": 0, "invulnerability": 0, "health": 100, "parrot_rest": [635.0, 4.0, 395.0], "combat": _combat()}
	check(ExplorationProtocol.actor(packet), "real co-op actor records accept the new eastern coast and parked bird")
	packet.position[0] = 1001
	check(not ExplorationProtocol.actor(packet), "expanded protocol still rejects out-of-bounds positions")
	packet.position[0] = NAN
	check(not ExplorationProtocol.actor(packet), "expanded protocol rejects non-finite positions")
	island.queue_free()
	walker.queue_free()
	await process_frame
	print("Volcanic expansion: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

func _floor(space: PhysicsDirectSpaceState3D, at: Vector2) -> Vector3:
	var ground := VolcanicTerrain.point(at)
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(ground + Vector3.UP * 8, ground - Vector3.UP * 2, 1))
	return hit.position if not hit.is_empty() else ground

func _combat() -> Dictionary:
	return {"owned": false, "selected": false, "guard": false, "active": false, "aim": [0, 1], "facing": [0, 1], "charge": 0, "strength": 0, "elapsed": 0, "punch": 0, "cooldown": 0, "drop": [635, 4, 395]}
