class_name CastleGate
extends Node3D
## A moving portcullis keeps its physical body with the visual and opens explicitly.

var body: StaticBody3D
var visual: MeshInstance3D
var opened: bool = false
var cutaway: bool = false
var full_size := Vector3(5.9, 7.6, 0.55)

func _ready() -> void:
	body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position.y = 3.8
	add_child(body)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = full_size
	collider.shape = shape
	body.add_child(collider)
	visual = MeadowGeometry.box(self, Vector3(0, 3.8, 0), full_size, Color("763b38"))
	visual.material_override = CastleMaterials.stone(Color("763b38"))
	SolidOcclusion.box(visual)
	var trim := CastleDecorationBatch.new()
	for x in [-2.1, -1.05, 0.0, 1.05, 2.1]:
		trim.box("bronze", Vector3(x, 0, 0.3), Vector3(0.12, 7.4, 0.1))
		for y in [-3.3, -1.1, 1.1, 3.3]: trim.box("iron", Vector3(x, y, 0.4), Vector3(0.22, 0.22, 0.08))
	for y in [-3.5, 0.0, 3.5]: trim.box("iron", Vector3(0, y, 0.33), Vector3(5.7, 0.16, 0.14))
	trim.crest(Vector3(0, 1.8, 0.42), 0, 0.75)
	trim.build(visual, "SealIronwork")
	CastleGeometry.title(self, Vector3(0, 1.5, 0.4), "ROYAL SEAL", 24)

func set_open(value: bool) -> void:
	opened = value
	body.collision_layer = 0 if value else 1
	visible = not value

func present(value: bool) -> void:
	cutaway = value
	visual.scale.y = 0.14 if value else 1.0
	visual.position.y = 0.532 if value else 3.8
