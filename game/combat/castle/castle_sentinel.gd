class_name CastleSentinel
extends CharacterBody3D
## One-life obsidian guardian follows chamber waypoints and never strikes through stone.

signal attacked(victim: Node3D, amount: float, source: Vector3)
signal defeated
var authoritative: bool = true
var target: Damageable
var quarry: Node3D
var route: Array[Vector3] = []
var home: int = 0
var waypoint: int = 0
var windup: float = 0.0
var cooldown: float = 0.0
var warning: Label3D
var torso: Node3D
var rank: int = 0
var ranged_threat: bool = false
var tactics := CastleSentinelTactics.new()
var spells := LavaSpellField.new()
var reaction := EnemyHitReaction.new()

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.55
	capsule.height = 1.8
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	torso = Node3D.new()
	add_child(torso)
	_box(Vector3(0, 0.9, 0), Vector3(1.1, 1.45, 0.85), Color("362b3a"))
	for x in [-0.3, 0.3]:
		_box(Vector3(x, 1.25, 0.45), Vector3(0.18, 0.13, 0.05), Color("ffb02e"))
		_box(Vector3(x, 0.18, 0), Vector3(0.38, 0.36, 0.6), Color("4b3840"))
	_box(Vector3(0, 0.7, 0.44), Vector3(0.12, 0.65, 0.07), Color("ff762b"))
	warning = Label3D.new()
	warning.position.y = 2.1
	warning.font_size = 26
	warning.pixel_size = 0.008
	warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	warning.text = "Ember Guardian"
	add_child(warning)
	target = Damageable.new()
	target.body = self
	target.maximum = 360 + rank * 60
	target.trains_weapons = true
	target.launch_immune = true
	target.knockback_multiplier = 0.0
	target.headshot_height = 1.2
	target.position.y = 0.9
	add_child(target)
	target.damage_filter = _filter_damage
	target.depleted.connect(func() -> void: set_alive(false); defeated.emit())
	target.hit.connect(_hit)
	spells.owner_body = self
	spells.bolt_limit = 6
	spells.field_limit = 0
	add_child(spells)

func _box(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if color.r < 0.8:
		material.albedo_texture = preload("res://assets/environment/lava_castle/basalt-masonry.png")
		material.albedo_color = color.lightened(0.6)
		material.roughness = 0.9
	if color.r > 0.8:
		material.emission_enabled = true
		material.emission = color
	mesh.material_override = material
	torso.add_child(mesh)

func _physics_process(delta: float) -> void:
	if not authoritative or target.current <= 0 or not is_instance_valid(quarry) or route.is_empty(): return
	spells.actors = [quarry]
	var offset := quarry.global_position - global_position
	var direction := tactics.step(self, delta, offset, clear_to(quarry.global_position))
	_present()
	velocity = Vector3(direction.x, velocity.y - 25 * delta, direction.z)
	move_and_slide()
	if tactics.skill == 2 and tactics.dash_time > 0 and global_position.distance_to(quarry.global_position) < 1.9 and clear_to(quarry.global_position):
		attacked.emit(quarry, 26, global_position)
		tactics.dash_time = 0
	if offset.length_squared() > 0.1: torso.rotation.y = atan2(offset.x, offset.z)

func _process(delta: float) -> void:
	if visible: reaction.present(torso, delta)

func destination() -> Vector3:
	if global_position.distance_to(quarry.global_position) < 9 and clear_to(quarry.global_position): return quarry.global_position
	var nearest := home
	var distance := INF
	for i in route.size():
		var value := route[i].distance_squared_to(quarry.global_position)
		if value < distance: distance = value; nearest = i
	if global_position.distance_to(route[waypoint]) < 0.4:
		waypoint += signi(nearest - waypoint)
	return route[waypoint]

func clear_to(at: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP, at + Vector3.UP, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func release_attack(offset: Vector3, clear: bool) -> void:
	if not is_instance_valid(quarry): return
	if tactics.skill == 1:
		var start := global_position + Vector3.UP * 1.15
		spells.bolt(start, (quarry.global_position + Vector3.UP * 0.75 - start).normalized(), 18)
	elif tactics.skill == 2:
		tactics.dash_time = 0.2
		tactics.dash_cooldown = 2.6
	elif offset.length() < 2.6 and clear: attacked.emit(quarry, 22, global_position)

func _filter_damage(amount: float, direction: Vector3, _kind: Damageable.HitKind) -> float:
	if not authoritative: return 0.0
	var front := Vector3(sin(torso.rotation.y), 0, cos(torso.rotation.y))
	return amount * 0.3 if tactics.shield > 0 and (-direction.normalized()).dot(front) > 0.25 else amount

func _hit(_amount: float, _direction: Vector3) -> void:
	reaction.flash(_direction)
	if target.last_hit_kind == Damageable.HitKind.SOY: tactics.request_dash(self)

func _present() -> void:
	warning.text = "! " + CastleSentinelTactics.NAMES[tactics.skill] if windup > 0 else ("GUARD · flank" if tactics.shield > 0 else "Ember Guardian · %d HP" % target.current)
	warning.modulate = Color("ff8950") if windup > 0 else (Color("83d9ee") if tactics.shield > 0 else Color("ffd68d"))

func set_alive(value: bool) -> void:
	visible = value
	collision_layer = 2 if value else 0
	if not value: target.current = 0
	if not value: spells.clear()
	set_physics_process(value)

func capture() -> Dictionary:
	return {"body": [global_position.x, global_position.y, global_position.z, target.current, waypoint, maxf(0, windup), cooldown, torso.rotation.y,
		tactics.skill, tactics.dash_time, tactics.dash_cooldown, tactics.shield, tactics.cycle, tactics.side, tactics.dash_direction.x, tactics.dash_direction.z], "spells": spells.capture()}

func apply(snapshot: Dictionary, authority: bool) -> void:
	var data: Array = snapshot.body
	global_position = Vector3(data[0], data[1], data[2])
	if float(data[3]) < target.current: reaction.flash()
	target.current = data[3]
	waypoint = int(data[4])
	windup = data[5]
	cooldown = data[6]
	torso.rotation.y = data[7]
	tactics.skill = int(data[8])
	tactics.dash_time = data[9]
	tactics.dash_cooldown = data[10]
	tactics.shield = data[11]
	tactics.cycle = int(data[12])
	tactics.side = data[13]
	tactics.dash_direction = Vector3(data[14], 0, data[15])
	spells.apply(snapshot.spells)
	spells.authoritative = authority
	authoritative = authority
	_present()
	set_alive(target.current > 0)
	set_physics_process(authority and target.current > 0)
