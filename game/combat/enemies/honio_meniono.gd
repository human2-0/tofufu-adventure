class_name HonioMeniono
extends TrainingMob
## Royale-only Easter egg. No adventure spawner, progression or save registration.
const HEALTH: float = 320
signal struck(victim: Node3D, amount: float, source: Vector3)
var survivors: Array[Damageable] = []
var melee := HonioMelee.new()
var art: HonioVisuals
var effects: HonioVFX
var speech: Label3D

func _ready() -> void:
	tuning = SnailTuning.new()
	tuning.dry_health = HEALTH
	tuning.dry_respawn = 900
	leash_radius = 38
	super._ready()
	_view_visibility._notifier.aabb = AABB(Vector3(-11, -1, -11), Vector3(22, 8, 22))
	var capsule := _collider.shape as CapsuleShape3D
	capsule.radius = 0.58
	capsule.height = 1.7
	_collider.position.y = 0.85
	target.position.y = 0.95
	target.headshot_height = 1.35
	target.launch_immune = true
	target.knockback_multiplier = 0.3
	target.damage_filter = _resist
	speech = MobLabels.make(self, "", 30, 0.012, Color("fff3bf"), 3.5)
	speech.width = 620
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warning.font_size = 30
	effects = HonioVFX.new()
	add_child(effects)

func _create_visual() -> void:
	art = HonioVisuals.new()
	add_child(art)

func _reaction_visual() -> Node3D:
	return art

func _present_visual(_aim: Vector3, delta: float) -> void:
	art.present(melee.facing, velocity.length_squared() > 0.2, melee.phase, melee.skill, melee.impact, delta)
	effects.present(melee, delta)
	var text_scale := clampf(720.0 / get_viewport().get_visible_rect().size.y, 1, 2)
	_nameplate.pixel_size = 0.008 * text_scale
	_warning.pixel_size = 0.010 * text_scale
	speech.pixel_size = 0.012 * text_scale
	_warning.position.y = 2.6 + 0.4 * text_scale
	speech.position.y = 2.6 + 0.9 * text_scale
	_warning.visible = melee.phase == HonioMelee.Phase.WARNING
	_warning.text = tr(["JAB!", "PROTEIN EXPRESS!", "TOFU TENDERIZER!"][melee.skill])
	_nameplate.text = "Honio Meniono"
	_nameplate.modulate = Color("87f6e4") if melee.phase == HonioMelee.Phase.RECOVERY else Color("ffcf75")
	speech.visible = melee.speech_time > 0 and melee.bark >= 0
	if speech.visible: speech.text = tr(HonioSpeech.LINES[melee.bark])

func _flash_visual() -> void:
	art.modulate = Color(3, 1.4, 0.8)

func _nameplate_text() -> String:
	return "Honio Meniono"

func _nameplate_height() -> float:
	return 2.6

func _choose_direction(delta: float) -> Vector3:
	return melee.step(self, delta)

func _resist(amount: float, _direction: Vector3, _kind: Damageable.HitKind) -> float:
	return amount * (1.0 if melee.phase == HonioMelee.Phase.RECOVERY else 0.75)

func _hit(_amount: float, direction: Vector3) -> void:
	_flash_visual()
	reaction.flash(direction)
	# Gunfire cannot permanently stunlock him; close melee interrupts a committed skill.
	var committed := melee.phase in [HonioMelee.Phase.WARNING, HonioMelee.Phase.RUSH]
	if committed and melee.interrupt_rest <= 0 and target.last_hit_kind in [Damageable.HitKind.MELEE, Damageable.HitKind.KNIFE]:
		melee.recover(0.7)
		melee.interrupt_rest = 2.5
		_windup = 0
		melee.impact = 0
		_knockback = Vector3(direction.x, 0, direction.z)

func _physics_process(delta: float) -> void:
	if target.paralysis > 0:
		melee.cancel()
		_windup = 0
	super._physics_process(delta)

func _die() -> void:
	melee.cancel()
	super._die()
