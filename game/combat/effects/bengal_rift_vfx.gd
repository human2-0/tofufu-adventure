class_name BengalRiftVFX
extends RefCounted
## Disposable alpha-textured slashes and a readable, depth-tested paralysis seal.

const RIFT: Texture2D = preload("res://assets/weapons/bengal_paws/reality-rift.png")

static func charge(combat: PlayerCombat) -> void:
	if DisplayServer.get_name() == "headless" or combat.has_node("ClawCharge"): return
	var tell := BengalClawAura.new()
	tell.name = "ClawCharge"
	tell.combat = combat
	combat.add_child(tell)

static func slash(owner: Node, at: Vector3, reality: bool, facing: Vector3 = Vector3.BACK) -> void:
	if DisplayServer.get_name() == "headless": return
	if reality:
		var effect := BengalRiftEffect.new()
		effect.facing = facing
		owner.add_child(effect)
		effect.global_position = at + Vector3.UP * 0.45
		return
	var sprite := Sprite3D.new()
	sprite.texture = RIFT
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.shaded = false
	sprite.pixel_size = 0.65 / RIFT.get_width()
	sprite.modulate = Color(1, 0.7, 0.28, 0.75)
	owner.add_child(sprite)
	sprite.global_position = at
	sprite.scale = Vector3.ONE * 0.5
	var tween := sprite.create_tween().set_parallel()
	tween.tween_property(sprite, "scale", Vector3.ONE * 1.15, 0.18)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(sprite.queue_free)

static func paralysis(target: Damageable) -> void:
	if DisplayServer.get_name() == "headless" or target.has_node("ParalysisSeal"): return
	var seal := BengalParalysisSeal.new()
	seal.name = "ParalysisSeal"
	seal.target = target
	target.add_child(seal)
