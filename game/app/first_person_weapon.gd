class_name FirstPersonWeapon
extends SubViewportContainer
## Cosmetic camera-space weapons. The isolated viewport prevents wall clipping.

var combat: PlayerCombat
var actor: CharacterBody3D
var _viewport: SubViewport
var _rig: Node3D
var _knife: Sprite3D
var _gun: Sprite3D
var _jet: SotjetVisual
var _hands: Array[MeshInstance3D] = []
var _phase: float = 0.0
var _kick: float = 0.0
var _shot: int = 0
var _swing: float = 0.0
var _was_active: bool = false
var _aim: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stretch = true
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.size = Vector2i(get_viewport_rect().size)
	add_child(_viewport)
	var camera := Camera3D.new()
	camera.fov = 60.0
	_viewport.add_child(camera)
	_rig = Node3D.new()
	_viewport.add_child(_rig)
	_rig.position = Vector3(0.32, -0.30, -1.0)
	_knife = _sprite(SwordVisual.ATLAS, Rect2(Vector2(SwordVisual.ATLAS.get_width() * 0.5, 0), Vector2(SwordVisual.ATLAS.get_size()) / Vector2(4, 2)), 0.0018)
	_gun = _sprite(SoyGunVisual.REAR, SoyGunVisual.REAR_REGIONS[0], 0.0018)
	_jet = SotjetVisual.new()
	_rig.add_child(_jet)
	_jet.set_process(false)
	_jet.frame = 5
	_jet.pixel_size = 0.0022
	_jet.offset = Vector2.ZERO
	for index in 2:
		var hand := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.075
		sphere.height = 0.15
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("fff0bd")
		sphere.material = material
		hand.mesh = sphere
		_rig.add_child(hand)
		_hands.append(hand)

func _sprite(source: Texture2D, region: Rect2, pixels: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = region
	sprite.texture = atlas
	sprite.pixel_size = pixels
	sprite.shaded = false
	_rig.add_child(sprite)
	return sprite

func _process(delta: float) -> void:
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if visible else SubViewport.UPDATE_DISABLED
	if not visible: return
	var moving := Vector2(actor.velocity.x, actor.velocity.z).length()
	_phase += delta * minf(moving, 8.0) * 1.8
	_aim = move_toward(_aim, 1.0 if combat.gun.aiming or combat.sotjet.aiming else 0.0, delta * 7.0)
	if combat.gun.shot_sequence != _shot:
		_shot = combat.gun.shot_sequence
		_kick = 1.0
	_kick = move_toward(_kick, 0.0, delta * 9.0)
	if combat.active and not _was_active: _swing = 0.0
	_was_active = combat.active
	_swing = minf(1.0, _swing + delta / (combat.tuning.heavy_swing_seconds if combat._strength >= 1.0 else combat.tuning.swing_seconds))
	var cut := sin(_swing * PI) if combat.active else 0.0
	var bob := Vector3(sin(_phase) * 0.012, absf(cos(_phase)) * 0.009, 0) * minf(moving, 1.0) * (1.0 - _aim)
	_rig.position = Vector3(lerpf(0.32, 0.0, _aim), lerpf(-0.30, -0.43, _aim), -1.0) + bob
	_rig.position += Vector3(-cut * 0.5, cut * 0.12, _kick * 0.07)
	_rig.rotation.z = cut * 1.1
	_knife.visible = combat.equipment.knife_owned and combat.equipment.knife_selected
	_gun.visible = combat.gun.selected
	_jet.visible = combat.sotjet.selected
	_knife.rotation.z = -0.25 - combat.rules.charge * 0.4
	if combat.equipment.guarding:
		_knife.rotation.z = 1.2
		_rig.position = Vector3(0.1, -0.1, -1.0)
	_hands[0].position = _knife.basis * Vector3(0.0, -0.145, 0.03) if _knife.visible else Vector3(0.0, -0.24, 0.03)
	_hands[1].position = Vector3(-0.22, -0.18, 0.02)
	_hands[1].visible = combat.ranged_selected() or not _knife.visible
	if not combat.ranged_selected() and not _knife.visible:
		_hands[0].position = Vector3(0.05, 0.0, 0.1)
		_hands[1].position = Vector3(-0.65, 0.0, 0.1)
		_hands[0].position.z -= sin(clampf(combat.equipment._punch_time / combat.tuning.punch_cooldown, 0, 1) * PI) * 0.25

func muzzle_position(world_camera: Camera3D, jet: bool) -> Vector3:
	var sprite: Sprite3D = _jet if jet else _gun
	var cell := Vector2(SotjetVisual.ATLAS.get_size()) / Vector2(5, 2) if jet else SoyGunVisual.REAR_REGIONS[0].size
	var landmark := SotjetVisual.MUZZLES[5] if jet else Vector2(0.5, 0.48)
	var point := Vector3((landmark.x - 0.5) * cell.x, (0.5 - landmark.y) * cell.y, 0) * sprite.pixel_size
	var overlay_camera := _viewport.get_camera_3d()
	var screen := overlay_camera.unproject_position(sprite.to_global(point)) / Vector2(_viewport.size)
	# Match the overlay's screen position even when world ADS changes its FOV.
	return world_camera.project_position(screen * world_camera.get_viewport().get_visible_rect().size, 0.6)
