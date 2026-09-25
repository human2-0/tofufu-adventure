class_name ArmoredSnail
extends TrainingMob
## Level-two meadow snail: shell armor deflects the first knife hit before opening briefly.

const LEVEL: int = 2
@export var armored_tuning: ArmoredSnailTuning = preload("res://game/combat/default_armored_snail.tres")
var _shell_open: float = 0.0
var _armored_visual: ArmoredSnailVisuals

func _ready() -> void:
	tuning = armored_tuning
	super()
	target.damage_filter = _filter_damage

func _physics_process(delta: float) -> void:
	_shell_open = maxf(0.0, _shell_open - delta)
	super(delta)

func _create_visual() -> void:
	_armored_visual = ArmoredSnailVisuals.new()
	add_child(_armored_visual)

func _present_visual(aim: Vector3, delta: float) -> void:
	_armored_visual.present(velocity, aim, _windup, _shell_open, delta)

func _flash_visual() -> void:
	_armored_visual.flash()

func _nameplate_text() -> String:
	return "ARMORED SNAIL · LV %d" % LEVEL

func _nameplate_height() -> float:
	return 1.75

func _filter_damage(amount: float, _direction: Vector3, kind: Damageable.HitKind) -> float:
	if kind == Damageable.HitKind.KNIFE and _shell_open <= 0.0:
		_shell_open = armored_tuning.knife_open_duration
		_armored_visual.dodge()
		CombatEffects.burst(get_parent(), global_position + Vector3.UP * 1.1, "SHELL DODGE", Color("bfe9f2"))
		return 0.0
	return amount * armored_tuning.armor_multiplier
