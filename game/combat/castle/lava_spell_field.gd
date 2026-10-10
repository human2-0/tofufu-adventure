class_name LavaSpellField
extends Node3D
## Bounded swept projectiles and delayed ground spells. Replicas only render records.

signal impacted(victim: Node3D, amount: float, source: Vector3, burning: bool)
var actors: Array[Node3D] = []
var owner_body: CollisionObject3D
var bolts: Array[Array] = []
var fields: Array[Array] = []
var ring_hits: Dictionary = {}
var art := LavaSpellVisuals.new()
var authoritative: bool = true
var bolt_limit: int = 24
var field_limit: int = 12
var _view_bolts: Array[Array] = []
var _view_fields: Array[Array] = []

func _ready() -> void:
	art.bolt_capacity = bolt_limit
	art.field_capacity = field_limit
	add_child(art)

func bolt(origin: Vector3, direction: Vector3, speed: float = 14.0, chunk: bool = false) -> void:
	if bolts.size() >= bolt_limit: return
	var velocity := direction.normalized() * speed
	bolts.append([origin.x, origin.y, origin.z, velocity.x, velocity.y, velocity.z, 2.3 if chunk else 3.5, 1 if chunk else 0])

func mark(at: Vector3, delay: float = 1.35, radius: float = 2.7) -> void:
	if fields.size() >= field_limit: return
	fields.append([0, at.x, at.y, at.z, -delay, 3.6, 0.0, radius])

func shockwave(at: Vector3) -> void:
	if fields.size() >= field_limit: return
	fields.append([1, at.x, at.y, at.z, -0.95, 1.7, 0.0, 0.0])
	ring_hits.clear()

func _physics_process(delta: float) -> void:
	if not authoritative: return
	_step_bolts(delta)
	_step_fields(delta)

func _process(delta: float) -> void:
	if authoritative:
		art.present(bolts, fields)
	else:
		for index in range(_view_bolts.size() - 1, -1, -1):
			var bolt_view := _view_bolts[index]
			var start := Vector3(bolt_view[0], bolt_view[1], bolt_view[2])
			var finish := start + Vector3(bolt_view[3], bolt_view[4], bolt_view[5]) * delta
			bolt_view[6] -= delta
			if bolt_view[6] <= 0 or not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start, finish, 1)).is_empty():
				_view_bolts.remove_at(index)
				continue
			for i in 3: bolt_view[i] = finish[i]
		for field_view in _view_fields:
			field_view[4] += delta
			if int(field_view[0]) == 1 and field_view[4] >= 0: field_view[7] = minf(20, field_view[4] * 11)
		art.present(_view_bolts, _view_fields)

func _step_bolts(delta: float) -> void:
	for i in range(bolts.size() - 1, -1, -1):
		var data := bolts[i]
		var start := Vector3(data[0], data[1], data[2])
		var finish := start + Vector3(data[3], data[4], data[5]) * delta
		var exclude: Array[RID] = []
		if is_instance_valid(owner_body): exclude.append(owner_body.get_rid())
		var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start, finish, 1, exclude))
		var stopped := not hit.is_empty()
		if not stopped:
			for actor in actors:
				if not is_instance_valid(actor): continue
				var near := Geometry3D.get_closest_point_to_segment(actor.global_position + Vector3.UP * 0.7, start, finish)
				if near.distance_to(actor.global_position + Vector3.UP * 0.7) < 0.7:
					impacted.emit(actor, 30 if data[7] == 1 else 19, start, true)
					stopped = true
					break
		data[0] = finish.x; data[1] = finish.y; data[2] = finish.z
		data[6] -= delta
		if stopped or data[6] <= 0: bolts.remove_at(i)

func _step_fields(delta: float) -> void:
	for i in range(fields.size() - 1, -1, -1):
		var data := fields[i]
		data[4] += delta
		if data[4] < 0: continue
		var at := Vector3(data[1], data[2], data[3])
		if int(data[0]) == 1:
			data[7] = data[4] * 11.0
			for actor in actors:
				if not is_instance_valid(actor) or ring_hits.has(actor.get_instance_id()): continue
				var offset := actor.global_position - at
				if absf(Vector2(offset.x, offset.z).length() - data[7]) < 1.2 and offset.y < 1.1 and offset.y > -0.2:
					ring_hits[actor.get_instance_id()] = true
					impacted.emit(actor, 24, at, false)
		else:
			data[6] -= delta
			if data[6] <= 0:
				data[6] = 0.6
				for actor in actors:
					if not is_instance_valid(actor): continue
					var offset := actor.global_position - at
					if Vector2(offset.x, offset.z).length() < data[7] and offset.y < 1.35 and offset.y > -0.2 and _clear(at, actor.global_position):
						impacted.emit(actor, 15, at, true)
		if data[4] >= data[5]: fields.remove_at(i)

func _clear(a: Vector3, b: Vector3) -> bool:
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a + Vector3.UP * 0.5, b + Vector3.UP * 0.5, 1)).is_empty()

func clear() -> void:
	_view_bolts.clear()
	_view_fields.clear()
	bolts.clear()
	fields.clear()
	ring_hits.clear()

func capture() -> Dictionary:
	return {"bolts": bolts.duplicate(true), "fields": fields.duplicate(true)}

func apply(data: Dictionary) -> void:
	bolts.assign(data.bolts.duplicate(true))
	fields.assign(data.fields.duplicate(true))
	_view_bolts.assign(data.bolts.duplicate(true))
	_view_fields.assign(data.fields.duplicate(true))
