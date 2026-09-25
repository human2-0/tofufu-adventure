class_name FactoryBean
extends CharacterBody3D
## One-life dungeon enemy. Variants share attack rules but use original factory art.

signal attacked(amount: float, source: Vector3)
signal defeated(at: Vector3)

enum Kind { SCOUT, BRUISER, WARDEN, DOFU }
const ART: Array[String] = [
	"res://assets/factory/evil_soy_scout.svg",
	"res://assets/factory/evil_soy_bruiser.svg",
	"res://assets/factory/evil_soy_warden.svg",
	"res://assets/factory/dofu_curd.svg"
]
const NAMES: Array[String] = ["Rogue Soybean", "Brine Bruiser", "Curd Warden", "Dofu · Awakened Curd"]
const HEALTH: Array[float] = [38.0, 80.0, 175.0, 65.0]
const DAMAGE: Array[float] = [8.0, 13.0, 18.0, 11.0]
const SPEED: Array[float] = [3.2, 2.0, 2.5, 2.8]

@export var kind: Kind = Kind.SCOUT
var quarry: Node3D
var target: Damageable
var _sprite: Sprite3D
var _warning: Label3D
var _windup: float = 0.0
var _rest: float = 0.0
var _knockback: Vector3 = Vector3.ZERO
var _alive: bool = true

func _ready() -> void:
	collision_layer = 2
	collision_mask = 3
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.43 if kind == Kind.SCOUT else 0.59
	capsule.height = 1.05 if kind == Kind.SCOUT else 1.35
	collider.shape = capsule
	collider.position.y = 0.55 if kind == Kind.SCOUT else 0.68
	add_child(collider)
	_sprite = Sprite3D.new()
	_sprite.texture = load(ART[kind]) as Texture2D
	_sprite.pixel_size = 0.0078 if kind == Kind.DOFU else 0.007 if kind == Kind.SCOUT else (0.009 if kind == Kind.BRUISER else 0.012)
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.position.y = 0.8 if kind == Kind.SCOUT else 1.0
	add_child(_sprite)
	_warning = Label3D.new()
	_warning.text = "!"
	_warning.font_size = 54
	_warning.pixel_size = 0.01
	_warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_warning.modulate = Color("ffcb6b")
	_warning.position.y = 1.7
	_warning.visible = false
	add_child(_warning)
	var nameplate := Label3D.new()
	nameplate.text = NAMES[kind]
	nameplate.font_size = 26
	nameplate.pixel_size = 0.007
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nameplate.modulate = Color("ffe4a7")
	nameplate.position.y = 1.4
	add_child(nameplate)
	target = Damageable.new()
	target.maximum = HEALTH[kind]
	target.headshot_height = 0.85
	target.body = self
	target.position.y = 0.65
	add_child(target)
	target.hit.connect(_on_hit)
	target.depleted.connect(_on_depleted)

func _physics_process(delta: float) -> void:
	if not _alive or not is_instance_valid(quarry): return
	_rest = maxf(0.0, _rest - delta)
	var offset := quarry.global_position - global_position
	offset.y = 0.0
	var direction := Vector3.ZERO
	if _windup > 0.0:
		_windup -= delta
		if _windup <= 0.0:
			_warning.visible = false
			if offset.length() < 2.1 and _clear_attack(): attacked.emit(DAMAGE[kind], global_position)
			_rest = 1.25
	elif _rest <= 0.0 and offset.length() < 1.75:
		_windup = 0.72 if kind != Kind.WARDEN else 0.95
		_warning.visible = true
	elif _rest <= 0.0 and offset.length() < 9.0:
		direction = offset.normalized() * SPEED[kind]
	velocity.x = direction.x + _knockback.x
	velocity.z = direction.z + _knockback.z
	velocity.y -= 25.0 * delta
	_knockback = _knockback.move_toward(Vector3.ZERO, 18.0 * delta)
	move_and_slide()
	_sprite.rotation.z = sin(Time.get_ticks_msec() * 0.006) * 0.06 if direction.length() > 0.1 else 0.0

func _clear_attack() -> bool:
	var from := global_position + Vector3.UP * 0.65
	var to := quarry.global_position + Vector3.UP * 0.65
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1)).is_empty()

func _on_hit(_amount: float, direction: Vector3) -> void:
	_knockback = Vector3(direction.x, 0, direction.z).limit_length(5.0)
	_windup = 0.0
	_warning.visible = false
	_sprite.modulate = Color("ff9d79")
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.2)

func _on_depleted() -> void:
	_alive = false
	visible = false
	collision_layer = 0
	set_physics_process(false)
	defeated.emit(global_position)
