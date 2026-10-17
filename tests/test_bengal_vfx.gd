extends SceneTree
## VFX lifecycle and presentation cannot modify damage, resources or status time.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(0, 3, 6)
	camera.look_at(Vector3.UP)
	var target := Damageable.new()
	target.paralysis_allowed = true
	stage.add_child(target)
	target.set_physics_process(false)
	target.paralyze(4)
	var effect := BengalRiftEffect.new()
	stage.add_child(effect)
	effect.set_process(false)
	effect.global_position = Vector3.UP
	effect._process(0.15)
	check(effect.rake.visible and effect.tear.visible, "initial triple rake opens a separate cosmic tear")
	check(effect.shards.multimesh.instance_count == 12, "shards use a fixed bounded instance pool")
	check((effect.tear.material_override as ShaderMaterial).get_shader_parameter("art") == BengalRiftEffect.OPEN, "generated open-rift art is applied to the effect material")
	camera.position.x += 3
	camera.look_at(Vector3.UP)
	effect._process(0.3)
	check(not effect.rake.visible and effect.tear.visible, "tear remains briefly after the claw sweep")
	check(effect.global_basis.z.dot(camera.global_basis.z) > 0.99, "rift stays readable when the observer moves")
	check(target.current == target.maximum and target.paralysis == 4, "visual updates never apply damage or advance paralysis")
	effect._process(0.61)
	check(effect.is_queued_for_deletion(), "rift and shards retire after their short lifetime")
	var seal := BengalParalysisSeal.new()
	seal.target = target
	target.add_child(seal)
	seal.set_process(false)
	seal._process(3.0)
	check(target.paralysis == 4 and not seal.is_queued_for_deletion(), "paralysis bonds read the authority timer without changing it")
	target._physics_process(4.0)
	seal._process(0.01)
	check(seal.is_queued_for_deletion(), "bonds disappear exactly when the enemy status expires")
	var combat := PlayerCombat.new()
	combat.actor = stage
	stage.add_child(combat)
	combat.claws.charging = true
	combat.claws.charge = 1.5
	var aura := BengalClawAura.new()
	aura.combat = combat
	combat.add_child(aura)
	aura.set_process(false)
	aura._process(0.5)
	check(aura.rakes.size() == 2 and aura.rakes[0].texture == BengalRiftVFX.RIFT, "charge tell applies generated claw art to both gathering rakes")
	var children := combat.get_child_count()
	combat.claws.charging = false
	combat.claws.dashing = true
	aura._process(0.05)
	check(combat.get_child_count() == children + 1, "dash emits a short-lived textured tear trail")
	aura.visible = false
	aura._process(0.1)
	check(combat.get_child_count() == children + 1, "hidden first-person world aura cannot spawn screen-filling trails")
	check(combat.vitals.current == 100 and target.current == target.maximum, "charge and dash VFX cannot spend SP or deal damage")
	combat.claws.cancel()
	aura._process(0.01)
	check(aura.is_queued_for_deletion(), "interruption or skill completion retires charge effect")
	stage.queue_free()
	await process_frame
	print("Bengal VFX: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
