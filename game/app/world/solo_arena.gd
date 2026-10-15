class_name SoloArena
extends Node
## Offline boss match lifecycle; gameplay is never simulated in a co-op replica.

var game: AdventureGame
var enabled: bool = true
var phase: String = "idle"
var remaining: float = 0.0
var boss: DofufuArenaBoss
var panel: SoloArenaPanel
var fighter := SoloArenaFighter.new()
var navigation := SoloArenaNavigation.new()
var _result: String = ""
var _enraged: bool = false

func _ready() -> void:
	panel = SoloArenaPanel.new()
	game.hud.add_child(panel)
	panel.challenged.connect(start)
	panel.surrendered.connect(func() -> void: finish("CHALLENGE ENDED · Your equipment is restored."))
	process_physics_priority = 20

func active() -> bool:
	return phase in ["entry", "fight"]

func _available() -> bool:
	return game.shooting_view.local_input != null and enabled and (game.opening == null or not game.opening.active) and game.health.current > 0.0 and not game.player.transport_active and not game.inventory_window.visible and not game.map.expanded and game.shooting_view.local_input.enabled and not game.shooting_view.local_input.chat_blocked

func _physics_process(delta: float) -> void:
	if not enabled:
		panel.hide()
		return
	if active():
		_contain()
		if phase == "entry":
			remaining = maxf(0.0, remaining - delta)
			game.health.invulnerability = 1.0
			if remaining == 0.0:
				phase = "fight"
				game.health.invulnerability = 0.0
				boss.running = true
				game.hud.announce("DOFUFU / FIGHT! Watch the orange warnings.")
		elif not _enraged and boss.rules.enraged:
			_enraged = true
			game.hud.announce("JADE DRAGON AWAKENS / Faster steps · seven returning blades!")
	elif phase == "complete":
		remaining = maxf(0.0, remaining - delta)
		if remaining == 0.0: phase = "idle"
	else:
		phase = "invite" if _available() and game.world.duel_arena.pad_for(game.player.global_position) >= 0 else "idle"
	_present()

func start() -> void:
	if active() or not _available() or game.world.duel_arena.pad_for(game.player.global_position) < 0: return
	fighter.enter(game)
	game.player.command_filter = prepare
	phase = "entry"
	remaining = 5.0
	_enraged = false
	boss = DofufuArenaBoss.new()
	boss.quarry = game.player
	boss.victim = game.health
	boss.hurt = _hurt
	boss.navigate = navigation.next
	boss.position = game.world.duel_arena.spawn_positions()[1] + Vector3.UP * 0.15
	game.add_child(boss)
	boss.target.depleted.connect(func() -> void: finish("VICTORY · You defeated Dofufu!"))
	navigation.build(boss, game.world.duel_arena.spawn_positions()[0] + Vector3.RIGHT * 15.0)
	game.combat.targets = [boss.target]
	game.combat.gun.targets = [boss.target]
	game.combat.sotjet.flow.targets = [boss.target]
	game.player.relocate(game.world.duel_arena.spawn_positions()[0] + Vector3.UP * 0.15)
	SoloArenaFighter.stop_motion(game.player)
	game.hud.announce("DOFUFU / Starts in 5 · 1: Celestial sword · 2: Soy raygun")
	_present()

func finish(result: String) -> void:
	if not active(): return
	phase = "complete"
	_result = result
	remaining = 5.0
	if is_instance_valid(boss):
		boss.clear_attacks()
		boss.collision_layer = 0
		boss.collision_mask = 0
		boss.queue_free()
	game.player.command_filter = Callable()
	fighter.leave(game)
	game.hud.announce(result)
	_present()

func defeated() -> bool:
	if not active(): return false
	finish("DEFEAT · Dofufu wins. Your equipment is restored.")
	return true

func prepare(command: PlayerCommand) -> void:
	if not active(): return
	command.drop_pressed = false
	command.pickup_pressed = false
	command.castle_action = -1
	command.use_healing_1 = false
	command.use_healing_2 = false
	command.use_healing_3 = false
	command.use_healing_4 = false
	if phase == "entry":
		command.move = Vector2.ZERO
		command.attack_held = false
		command.punch_held = false
		command.guard_held = false
		command.jump_held = false
		command.jump_pressed = false
		command.dash_held = false
		command.dash_pressed = false
		command.cancel_actions = true

func checkpoint(data: Dictionary) -> Dictionary:
	return fighter.checkpoint(data) if active() else data

func _hurt(amount: float, source: Vector3, impulse: Vector3) -> void:
	if phase != "fight" or game.player.motor.is_dashing: return
	if game.combat.equipment.defend(source, amount): return
	amount *= game.combat.incoming_damage_multiplier
	if game.health.damage(amount, impulse, Damageable.HitKind.MELEE):
		game.health.invulnerability = maxf(game.health.invulnerability, 0.65)

func _contain() -> void:
	var arena := game.world.duel_arena
	if not arena.contains_arena(game.player.global_position):
		game.player.global_position = arena.constrained_position(game.player.global_position)
		SoloArenaFighter.stop_motion(game.player)
	if is_instance_valid(boss) and not arena.contains_arena(boss.global_position):
		boss.global_position = arena.constrained_position(boss.global_position)
		boss.velocity = Vector3.ZERO

func _present() -> void:
	game.hud._notice.offset_top = 208 if phase in ["invite", "entry", "fight"] else 118
	game.hud._notice.offset_bottom = game.hud._notice.offset_top + 28
	var text := "2400 HP · Celestial weapon loans · No equipment loss"
	if phase == "entry": text = "STARTS IN %d · 1: Sword / guard · 2: Raygun" % ceili(remaining)
	if phase == "fight":
		text = DofufuRules.NAMES[boss.rules.skill] if boss.rules.windup > 0.0 else ("JADE DRAGON · ENRAGED" if boss.rules.enraged else "Dodge · guard · use cover · R to reload")
	if phase == "complete": text = _result
	panel.present(phase, boss.target.current if is_instance_valid(boss) else 0.0, 2400.0, text)
