class_name BattleAimView
extends Node
## Reuses adventure's reticle and precise camera view without resolving shots.
var game: BattleRoyaleGame
var reticle: GunReticle

func _ready() -> void:
	reticle = GunReticle.new()
	game.hud.add_child(reticle)

func _process(_delta: float) -> void:
	var combat := game.combat.fighters[game.local_slot].combat
	game.camera.precise = combat.gun.aiming or combat.sotjet.aiming or combat.bow.charge > 0
	reticle.visible = game.playing and game.local_input.enabled and combat.ranged_selected()
	reticle.precise = game.camera.precise or combat.bow.selected
	reticle.recoil = combat.gun.recoil.heat
	reticle.centered = false
	reticle.reload_remaining = combat.bow.reload_remaining if combat.bow.selected else (combat.gun.reload_remaining if combat.gun.selected else 0.0)
	reticle.reload_progress = SoyGunReloadPose.progress(reticle.reload_remaining)
	reticle.queue_redraw()
