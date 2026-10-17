class_name BengalClawAura
extends Node3D
## Existing generated rake texture gathers at both paws and tears a dash trail.

var combat: PlayerCombat
var rakes: Array[Sprite3D] = []
var age: float = 0.0
var trail_time: float = 0.0

func _ready() -> void:
	for index in 2:
		var rake := Sprite3D.new()
		rake.texture = BengalRiftVFX.RIFT
		rake.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		rake.shaded = false
		rake.pixel_size = 0.8 / rake.texture.get_width()
		add_child(rake)
		rakes.append(rake)

func _process(delta: float) -> void:
	if not combat.claws.busy():
		queue_free()
		return
	if not visible: return
	age += delta
	global_position = combat.actor.global_position + Vector3.UP * 0.85
	var power := 1.0 if combat.claws.dashing else clampf(combat.claws.charge / BengalClaws.CHARGE_SECONDS, 0.0, 1.0)
	var forward := Vector3(combat.claws.aim.x, 0, combat.claws.aim.y)
	var across := Vector3(forward.z, 0, -forward.x)
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		rakes[index].position = across * side * (0.32 + power * 0.12) + forward * 0.3
		rakes[index].scale = Vector3.ONE * (0.35 + power * 0.65 + sin(age * 22) * 0.035)
		rakes[index].modulate = Color(0.8, 0.55 + power * 0.3, 1.0, 0.25 + power * 0.7)
	if not combat.claws.dashing: return
	trail_time -= delta
	if trail_time <= 0.0:
		trail_time = 0.045
		_trail(forward)

func _trail(forward: Vector3) -> void:
	var rake := Sprite3D.new()
	rake.texture = BengalRiftVFX.RIFT
	rake.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rake.shaded = false
	rake.pixel_size = 1.1 / rake.texture.get_width()
	rake.modulate = Color(0.7, 0.8, 1.0, 0.7)
	combat.add_child(rake)
	rake.global_position = global_position - forward * 0.4
	var tween := rake.create_tween().set_parallel()
	tween.tween_property(rake, "scale", Vector3.ONE * 0.4, 0.25)
	tween.tween_property(rake, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(rake.queue_free)
