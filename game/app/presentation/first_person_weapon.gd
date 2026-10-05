class_name FirstPersonWeapon
extends SubViewportContainer
## Cosmetic camera-space weapons. The isolated viewport prevents wall clipping.

var combat: PlayerCombat
var actor: CharacterBody3D
var run_lowering: float = 0.0
var _viewport: SubViewport
var _rig: Node3D
var _melee_root: Node3D
var _melee_model: Node3D
var _melee_item_id: String = ""
var _staff: StaffVisual
var _gun: Sprite3D
var _jet: SotjetVisual
var _hands: Array[MeshInstance3D] = []
var _arms := FirstPersonArms.new()
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
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 0.2, 0.1)
	light.omni_range = 5.0
	light.light_energy = 2.0
	_viewport.add_child(light)
	_rig = Node3D.new()
	_viewport.add_child(_rig)
	_rig.position = Vector3(0.32, -0.30, -1.0)
	_melee_root = Node3D.new()
	_melee_root.visible = false
	_rig.add_child(_melee_root)
	_set_melee_model("knife")
	_staff = StaffVisual.new()
	_rig.add_child(_staff)
	_staff.position = Vector3(0.16, 0.11, -0.30)
	_gun = _sprite(SoyGunVisual.REAR, SoyGunVisual.REAR_REGIONS[0], 0.0018)
	_jet = SotjetVisual.new()
	_jet.first_person_view = true
	_jet.visible = false
	_rig.add_child(_jet)
	_viewport.add_child(_arms)
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
		hand.material_override = _arms.material
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

func _set_melee_model(item_id: String) -> void:
	if item_id == _melee_item_id: return
	if _melee_model != null:
		_melee_root.remove_child(_melee_model)
		_melee_model.free()
	_melee_item_id = item_id
	var packed := WeaponModelCatalog.scene_for(item_id)
	if packed == null: return
	_melee_model = packed.instantiate() as Node3D
	_melee_root.add_child(_melee_model)
	var direction := Basis(Vector3.BACK, -PI * 0.5) if item_id == "knife" else Basis.IDENTITY
	_melee_model.transform = Transform3D(direction.scaled(Vector3.ONE * 0.42), Vector3.ZERO)

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
	var stabbing := combat.active and combat.attack_style == KnifeAttack.Style.STAB
	var diving := (combat.active and combat.attack_style == KnifeAttack.Style.AIR_SLASH) or combat.plunge.active
	var swing_seconds := combat._attack_duration()
	_swing = minf(1.0, _swing + delta / swing_seconds)
	var cut := sin(_swing * PI) if combat.active else 0.0
	var bob := Vector3(sin(_phase) * 0.012, absf(cos(_phase)) * 0.009, 0) * minf(moving, 1.0) * (1.0 - _aim)
	_rig.position = Vector3(lerpf(0.32, 0.0, _aim), lerpf(-0.30, -0.43, _aim), -1.0) + bob
	_rig.position += Vector3(0, -cut * 0.38, -cut * 0.3) if diving else (Vector3(0, 0, -cut * 0.48) if stabbing else Vector3(-cut * 0.5, cut * 0.12, 0))
	_rig.position.z += _kick * 0.07
	_rig.rotation.z = _swing * TAU if combat.active and combat.attack_style == StaffAttack.TORNADO else (cut * -0.5 if diving else (cut * -0.15 if stabbing else cut * 1.1))
	_rig.rotation.x = -GunRunPose.PITCH * run_lowering
	_rig.rotation.z += 0.12 * run_lowering
	_rig.position += Vector3(0.04, -0.07, 0.04) * run_lowering
	var melee_item := "nori_katana" if combat.equipment.nori_selected else ("edamame_sword" if combat.equipment.pod_selected else "knife")
	_set_melee_model(melee_item)
	var melee_visible := combat.equipment.knife_owned and combat.equipment.knife_selected
	_melee_root.visible = melee_visible
	_staff.visible = combat.equipment.staff_owned and combat.equipment.staff_selected
	_staff.show_charge(combat.rules.charge, combat.active and combat.attack_style == StaffAttack.TORNADO)
	_gun.visible = combat.gun.selected
	_jet.visible = combat.sotjet.selected
	_melee_model.rotation.z = ( -PI * 0.5 if melee_item == "knife" else 0.0) + (PI if combat.plunge.active or combat.plunge.recovery > 0 else -0.25 - combat.rules.charge * 0.4)
	if combat.equipment.guarding:
		_melee_model.rotation.z = (-PI * 0.5 if melee_item == "knife" else 0.0) + 1.2
		_rig.position = Vector3(0.1, -0.1, -1.0)
	_place_hands(melee_visible)
	if combat.gun.selected:
		var remaining := combat.gun.reload_remaining
		var reload_weight := SoyGunReloadPose.weight(remaining)
		_rig.position += Vector3(-0.08, -0.08, 0.08) * reload_weight
		_rig.rotation.z += SoyGunReloadPose.roll(remaining)
		_hands[1].position += Vector3(0.2, 0.24, 0.08) * SoyGunReloadPose.feed(remaining)

	_arms.present(_hands, FufuRightHand.tint((actor as Player).visuals.worn_set) if actor is Player else Color("fff0bd"))

func _place_hands(melee_visible: bool) -> void:
	_hands[1].position = Vector3(-0.13, -0.18, 0.02)
	_hands[1].visible = combat.ranged_selected()
	if melee_visible:
		_hands[0].position = _rig.to_local(_melee_model.to_global(WeaponModelCatalog.GRIPS[_melee_item_id]))
	elif _staff.visible:
		_hands[0].position = _rig.to_local(_staff.model_grip_position())
	elif _jet.visible:
		_jet.refresh()
		_hands[0].position = _rig.to_local(_jet.model_grip_position())
		_hands[1].position = _rig.to_local(_jet._model.to_global(Vector3(-0.35, -0.18, 0)))
	elif _gun.visible:
		# Same grip landmark as the third-person gun: source x=.5, y=.75.
		_hands[0].position = _rig.to_local(_gun.to_global(Vector3(0, -SoyGunVisual.REAR_REGIONS[0].size.y * 0.25, 0) * _gun.pixel_size))
	else:
		_hands[1].visible = true
		_hands[0].position = Vector3(0.05, 0.0, 0.1)
		_hands[1].position = Vector3(-0.65, 0.0, 0.1)
		_hands[0].position.z -= sin(clampf(combat.equipment._punch_time / combat.tuning.punch_cooldown, 0, 1) * PI) * 0.25

func muzzle_position(world_camera: Camera3D, jet: bool) -> Vector3:
	var overlay_camera := _viewport.get_camera_3d()
	var screen_position := _jet.muzzle_position() if jet else _gun.to_global(Vector3(0.0, 0.0, 0.0))
	if not jet:
		var region := SoyGunVisual.REAR_REGIONS[0].size
		var point := Vector3(0.0, region.y * 0.02, 0) * _gun.pixel_size
		screen_position = _gun.to_global(point)
	var screen := overlay_camera.unproject_position(screen_position) / Vector2(_viewport.size)
	# Match the overlay's screen position even when world ADS changes its FOV.
	return world_camera.project_position(screen * world_camera.get_viewport().get_visible_rect().size, 0.6)
