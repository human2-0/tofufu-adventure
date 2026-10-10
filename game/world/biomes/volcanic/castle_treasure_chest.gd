class_name CastleTreasureChest
extends Node3D
## Textured hinged treasure, local opening sparks and an unclaimed-loot glow.

var lid: Node3D
var gleam: Node3D
var sparks: MultiMeshInstance3D
var opened: bool = false
var _pulse: float = 0.0
var _tween: Tween
var _wood := ShaderMaterial.new()

func _ready() -> void:
	_wood.shader = preload("res://game/world/biomes/volcanic/castle_chest_wood.gdshader")
	var base := CastleGeometry.solid(self, Vector3(0, 0.48, 0), Vector3(1.5, 0.96, 1.1), Color("563627"))
	base.visible = false
	_shell()
	lid = Node3D.new()
	lid.position = Vector3(0, 0.98, -0.55)
	add_child(lid)
	var top := MeadowGeometry.box(lid, Vector3(0, 0, 0.55), Vector3(1.58, 0.2, 1.18), Color.WHITE)
	top.material_override = _wood
	var trim := CastleDecorationBatch.new()
	var lid_trim := CastleDecorationBatch.new()
	for x in [-0.58, 0.58]:
		trim.box("bronze", Vector3(x, 0.48, 0.57), Vector3(0.14, 0.86, 0.06))
		lid_trim.box("bronze", Vector3(x, 0.115, 0.55), Vector3(0.14, 0.05, 1.2))
	trim.box("iron", Vector3(0, 0.7, 0.6), Vector3(0.24, 0.32, 0.07))
	trim.crest(Vector3(0, 0.4, 0.61), 0, 0.25)
	trim.build(self, "ChestBindings")
	lid_trim.build(lid, "LidBindings")
	gleam = Node3D.new()
	add_child(gleam)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("ffda67")
	gold.emission_enabled = true
	gold.emission = Color("ffa72d")
	gold.emission_energy_multiplier = 1.5
	for i in 3:
		var chunk := MeadowGeometry.box(gleam, Vector3(-0.38 + i * 0.38, 0.46 + (i % 2) * 0.13, 0), Vector3(0.32, 0.24, 0.36), Color.WHITE)
		chunk.material_override = gold
		chunk.rotation.y = i * 0.3
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * 0.07
	cube.material = gold
	multi.mesh = cube
	multi.instance_count = 20
	sparks = MultiMeshInstance3D.new()
	sparks.multimesh = multi
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)
	sparks.visible = false
	set_process(false)

func _shell() -> void:
	for z in [-0.51, 0.51]:
		MeadowGeometry.box(self, Vector3(0, 0.48, z), Vector3(1.5, 0.96, 0.08), Color.WHITE).material_override = _wood
	for x in [-0.71, 0.71]:
		MeadowGeometry.box(self, Vector3(x, 0.48, 0), Vector3(0.08, 0.96, 0.94), Color.WHITE).material_override = _wood
	MeadowGeometry.box(self, Vector3(0, 0.08, 0), Vector3(1.34, 0.16, 0.94), Color.WHITE).material_override = _wood

func present(value: bool, unclaimed: bool, animate: bool) -> void:
	gleam.visible = unclaimed
	if not animate:
		if is_instance_valid(_tween): _tween.kill()
		opened = value
		lid.rotation.x = -1.2 if value else 0.0
		_pulse = 0
		sparks.visible = false
		set_process(false)
		return
	if value == opened: return
	opened = value
	if is_instance_valid(_tween): _tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(lid, "rotation:x", -1.2 if value else 0.0, 0.65)
	if value:
		_pulse = 1.4
		sparks.visible = true
		set_process(true)

func _process(delta: float) -> void:
	_pulse = maxf(0, _pulse - delta)
	var elapsed := 1.4 - _pulse
	for i in 20:
		var angle := i * 2.39996
		var radius := elapsed * (0.3 + (i % 4) * 0.09)
		var at := Vector3(cos(angle) * radius, 1.0 + elapsed * 1.8 - elapsed * elapsed * 0.55, sin(angle) * radius)
		var scale_factor := minf(1.0, _pulse * 3)
		sparks.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_factor), at))
	if _pulse <= 0:
		sparks.visible = false
		set_process(false)
