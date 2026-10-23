class_name HonioVFX
extends Node3D
## Fixed reusable textured effects: zero particles, lights or disposable attack nodes.
const SHEET: String = "res://assets/combat/honio_meniono/skills.png"
var sheet: Texture2D
var ring: Sprite3D
var impact: Sprite3D
var trail: Sprite3D
var dust: Sprite3D
var health: MeshInstance3D
var health_material: StandardMaterial3D

func _ready() -> void:
	sheet = load(SHEET) as Texture2D
	ring = _sprite(3, false)
	ring.rotation.x = -PI / 2
	# Solid outer bounds are 467 x 456 pixels, centred at (302.5, 283).
	ring.pixel_size = 6.0 / 467.0
	ring.offset = Vector2(11, -30.5)
	impact = _sprite(0, true)
	impact.pixel_size = 0.003
	trail = _sprite(1, false)
	trail.pixel_size = 0.006
	trail.position.y = 0.8
	dust = _sprite(2, true)
	dust.pixel_size = 0.005
	dust.position.y = 0.65
	_bar(Color("253239"), 1.6)
	health = _bar(Color("ffcf75"), 1.48)
	health_material = health.material_override as StandardMaterial3D
	health.position.z = 0.01

func _sprite(index: int, billboard: bool) -> Sprite3D:
	var sprite := Sprite3D.new()
	var cell := Vector2(sheet.get_size()) * 0.5
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = Rect2(Vector2(index % 2, floori(index / 2.0)) * cell, cell)
	texture.filter_clip = true
	sprite.texture = texture
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.visibility_range_end = 140
	sprite.hide()
	add_child(sprite)
	return sprite

func _bar(tint: Color, width: float) -> MeshInstance3D:
	var bar := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(width, 0.1)
	bar.mesh = quad
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_color = tint
	bar.material_override = material
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bar.visibility_range_end = 32
	bar.position.y = 2.38
	add_child(bar)
	return bar

func present(melee: HonioMelee, _delta: float) -> void:
	ring.visible = melee.phase == HonioMelee.Phase.WARNING and melee.skill != HonioMelee.Skill.JAB
	ring.position = Vector3(0, 0.065, 0)
	ring.rotation = Vector3(-PI / 2, 0, 0)
	ring.scale = Vector3(1, 467.0 / 456.0, 1)
	if melee.skill == HonioMelee.Skill.PROTEIN_EXPRESS:
		ring.position += melee.aim * 3.75
		ring.rotation.y = atan2(melee.aim.x, melee.aim.z)
		# Include the fist contact reach beyond the moving capsule, with a safe margin.
		ring.scale *= Vector3(1, 2, 1)
	ring.modulate.a = 0.8 + sin(melee.remaining * 22) * 0.18
	trail.visible = melee.phase == HonioMelee.Phase.RUSH
	trail.position = Vector3.UP * 0.7 - melee.facing * 1.2
	var camera := get_viewport().get_camera_3d()
	if trail.visible and camera != null:
		var angle := atan2(melee.facing.dot(camera.global_basis.y), melee.facing.dot(camera.global_basis.x)) - PI
		trail.global_basis = camera.global_basis * Basis(Vector3.BACK, angle)
	impact.visible = melee.impact > 0 and melee.skill != HonioMelee.Skill.TOFU_TENDERIZER
	impact.position = Vector3.UP * 0.85 + melee.aim * 0.85
	impact.modulate.a = clampf(melee.impact * 4, 0, 1)
	dust.visible = melee.impact > 0 and melee.skill == HonioMelee.Skill.TOFU_TENDERIZER
	dust.scale = Vector3.ONE * (1.6 - melee.impact * 2)
	dust.modulate.a = clampf(melee.impact * 4, 0, 1)
	var mob := get_parent() as HonioMeniono
	health.scale.x = maxf(0.001, mob.target.current / mob.target.maximum)
	health_material.albedo_color = Color("87f6e4") if melee.phase == HonioMelee.Phase.RECOVERY else Color("ffcf75")
