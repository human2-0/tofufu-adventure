class_name Dofufu
extends FactoryBean
## Authoritative hostile clone. It owns no Player, inventory, or input state.

signal attack_telegraphed(attack_name: String, duration: float)
signal phase_changed(phase: int)

enum Phase { APPROACH, WINDUP, DASH, RECOVERY, DEAD }
const BASE_HEALTH: float = 800.0
const COMBO_DAMAGE: Array[float] = [15.0, 18.0, 26.0]
const COMBO_WINDUP: Array[float] = [0.48, 0.42, 0.66]
const COMBO_RECOVERY: Array[float] = [0.24, 0.28, 0.9]
const DASH_RANGE: float = 6.5

@export_range(1, 8, 1) var combat_participants: int = 1
var phase: Phase = Phase.APPROACH
var second_phase: bool = false
var _clock: float = 0.0
var _combo: int = 0
var _attack: String = ""
var _dash_direction := Vector3.ZERO
var _dash_hit: bool = false
var _next_dash: float = 5.0
var _next_slam: float = 8.0
var _katana: Sprite3D
var _aura: MeshInstance3D

func _ready() -> void:
	kind = Kind.DOFUFU
	super._ready()
	target.maximum = BASE_HEALTH * (1.0 + 0.5 * float(combat_participants - 1)) * health_scale
	target.current = target.maximum
	_sprite.modulate = Color("e9b8e8")
	_sprite.position.y = 0.55
	_sprite.texture = preload("res://assets/characters/fufu/sets/dark_leaf_standing.png")
	_sprite.hframes = 5
	_sprite.vframes = 1
	_sprite.frame = 2
	_sprite.pixel_size = 0.002
	_warning.text = "!"
	_warning.position.y = 2.0
	_add_katana()
	_add_aura()
	for child in get_children():
		if child is Label3D and child != _warning:
			child.text = "DOFUFU · HOSTILE CLONE"
			child.modulate = Color("ff8fe6")
			child.position.y = 1.7

func _physics_process(delta: float) -> void:
	if not _alive or not is_instance_valid(quarry): return
	if not second_phase and target.current <= target.maximum * 0.5:
		second_phase = true
		phase_changed.emit(2)
	_clock += delta
	_next_dash = maxf(0.0, _next_dash - delta)
	_next_slam = maxf(0.0, _next_slam - delta)
	var toward := quarry.global_position - global_position
	toward.y = 0.0
	if toward.length() < 11.0: targeting.emit(quarry)
	match phase:
		Phase.APPROACH: _approach(toward)
		Phase.WINDUP: _windup_step(toward)
		Phase.DASH: _dash_step(toward)
		Phase.RECOVERY: _recovery_step()
	velocity.y -= 25.0 * delta
	var hit_wall := is_on_wall()
	move_and_slide()
	if phase == Phase.DASH and (hit_wall or is_on_wall()): _recover(0.55)
	_face(toward)

func _approach(toward: Vector3) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _next_slam <= 0.0 and second_phase and toward.length() < 3.2:
		_begin("Nori slam", 1.0)
	elif _next_dash <= 0.0 and toward.length() > 2.1 and toward.length() < DASH_RANGE:
		_begin("Dash slash", 0.65)
	elif toward.length() < 2.3:
		_begin("Katana %d" % (_combo + 1), COMBO_WINDUP[_combo])
	elif toward.length() < 10.0 and _clear_attack():
		velocity.x = toward.normalized().x * 3.4
		velocity.z = toward.normalized().z * 3.4

func _begin(name: String, duration: float) -> void:
	phase = Phase.WINDUP
	_attack = name
	_clock = 0.0
	_warning.visible = true
	_warning.text = "! " + name
	attack_telegraphed.emit(name, duration)

func _windup_step(toward: Vector3) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	var duration := 1.0 if _attack == "Nori slam" else 0.65 if _attack == "Dash slash" else COMBO_WINDUP[_combo]
	if _clock < duration: return
	_warning.visible = false
	if _attack == "Dash slash":
		phase = Phase.DASH
		_clock = 0.0
		_dash_hit = false
		_dash_direction = toward.normalized()
		_next_dash = 6.0
		return
	if _attack == "Nori slam":
		if toward.length() <= 3.0 and _clear_attack(): attacked.emit(30.0 * damage_scale, global_position)
		_next_slam = 8.0
		_recover(0.7)
		return
	if toward.length() <= 2.7 and _clear_attack(): attacked.emit(COMBO_DAMAGE[_combo] * damage_scale, global_position)
	var recovery := COMBO_RECOVERY[_combo]
	_combo = (_combo + 1) % 3
	_recover(recovery)

func _dash_step(toward: Vector3) -> void:
	velocity.x = _dash_direction.x * 11.0
	velocity.z = _dash_direction.z * 11.0
	if not _dash_hit and toward.length() <= 2.0 and _clear_attack():
		_dash_hit = true
		attacked.emit(24.0 * damage_scale, global_position)
	if _clock >= 0.42: _recover(0.65)

func _recover(duration: float) -> void:
	phase = Phase.RECOVERY
	_clock = -duration
	_warning.visible = false
	velocity.x = 0.0
	velocity.z = 0.0

func _recovery_step() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _clock >= 0.0:
		phase = Phase.APPROACH
		_clock = 0.0

func _face(toward: Vector3) -> void:
	var facing := 2
	if absf(toward.x) > absf(toward.z): facing = 0 if toward.x > 0.0 else 4
	elif toward.z < 0.0: facing = 6
	_sprite.frame = 0 if facing == 6 else 4 if facing == 2 else 2
	_sprite.flip_h = facing == 0
	_katana.flip_h = toward.x < 0.0
	_katana.position.x = -0.43 if toward.x < 0.0 else 0.43

func _on_depleted() -> void:
	phase = Phase.DEAD
	_warning.visible = false
	super._on_depleted()

func _add_katana() -> void:
	_katana = Sprite3D.new()
	_katana.texture = preload("res://assets/weapons/nori/nori_katana.png")
	_katana.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_katana.pixel_size = 0.0015
	_katana.position = Vector3(0.43, 0.85, 0.05)
	_katana.scale = Vector3(0.35, 0.35, 0.35)
	add_child(_katana)

func _add_aura() -> void:
	_aura = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.72
	ring.outer_radius = 0.82
	_aura.mesh = ring
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ad3cc9")
	material.emission_enabled = true
	material.emission = Color("a328b0")
	_aura.material_override = material
	_aura.position.y = 0.06
	add_child(_aura)
