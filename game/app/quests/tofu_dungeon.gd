class_name TofuDungeon
extends Node
## App composition for entry, encounter waves, processing timers, loot and unlock.

signal puzzle_command_requested(command: TofuPuzzleCommand)
var game: Node3D
var state := TofuDungeonState.new()
var rewards := TofuRewardLedger.new()
var stashes := TofuStashRules.new()
var puzzle := TofuDungeonAttempt.new()
var puzzle_runtime := DungeonPuzzleRuntime.new()
var puzzle_flow := DungeonPuzzleFlow.new()
var puzzle_views: DungeonPuzzleViews
var run_menu: DungeonRunMenu
var journal: DungeonRecipeJournal
var actor_ids: Dictionary = {}
var boss_members: Array[String] = []
var puzzle_clock: float = 0.0
var puzzle_enabled: bool = true
var factory: TofuFactory
var enabled: bool = true
var cooperative: bool = false
var party: Dictionary = {}
var _carrying: Dictionary = {}
var _connected: Array[Player] = []
var _inside: bool = false
var _cooldown: float = 0.0
var _party_cooldowns: Dictionary = {}
var _recovery := DungeonRecovery.new()
var _spawned_stage: int = -1
var _enemies: Array[FactoryBean] = []
var _enemy_reward_ids: Dictionary = {}
var _crates: Array[FactoryCrate] = []
var _replica_enemies: Array[FactoryBean] = []
var _replica_crates: Array[FactoryCrate] = []
func _ready() -> void:
	factory = game.world.tofu_factory
	puzzle.configure(1, 1, randi())
	puzzle_runtime.configure(self, puzzle)
	puzzle_views = DungeonPuzzleViews.new()
	add_child(puzzle_views)
	puzzle_views.configure(self, game.player, game.camera, puzzle, game.health)
	puzzle_views.command_requested.connect(_puzzle_view_command)
	DungeonRunActions.attach(self)
	DungeonTrialLifecycle.bind(self, game.player, game.health)
	state.changed.connect(_sync_unlock)
	_sync_unlock()
	_connect_actor(game.player)

func _process(delta: float) -> void:
	DungeonProductionPresentation.step(self, delta)

func _physics_process(delta: float) -> void:
	if not enabled or game.opening != null and game.opening.active: return
	puzzle_clock += delta
	for carrier: Player in _carrying.keys():
		if not is_instance_valid(carrier) or not TofuFactory.contains(carrier.global_position): _carrying.erase(carrier)
	factory.show_cargo(cargo_positions())
	if cooperative:
		_step_party_portals(delta)
		if _party_inside():
			_recovery.step(self)
			_advance_inside(delta)
		return
	if _inside: _recovery.step(self)
	_cooldown = maxf(0.0, _cooldown - delta)
	if _inside:
		if _cooldown <= 0.0 and (factory.entrance_inside_reached(game.player) or state.completed and factory.exit_reached(game.player)):
			_exit()
			return
		_advance_inside(delta)
	elif _cooldown <= 0.0 and factory.entrance_reached(game.player):
		_enter()

func configure_party(members: Dictionary, authority: bool) -> void:
	cooperative = true
	party = members
	enabled = authority
	set_physics_process(authority)
	_sync_unlock()

func _step_party_portals(delta: float) -> void:
	DungeonMembership.step_party_portals(self, delta)

func _party_inside() -> bool:
	for member: CoopActor in party.values():
		if is_instance_valid(member.actor) and actor_in_run(member.actor): return true
	return false

func _advance_inside(delta: float) -> void:
	if puzzle_enabled: puzzle_flow.advance(self)
	else: DungeonStage.advance_inside(self, delta)

func _actors_inside() -> Array[Node3D]:
	var result: Array[Node3D] = []
	if not cooperative:
		if _inside: result.append(game.player)
		return result
	for member: CoopActor in party.values():
		if is_instance_valid(member.actor) and actor_in_run(member.actor): result.append(member.actor)
	return result

func _enter() -> void:
	factory.ensure_interior()
	_inside = true
	DungeonMembership.enter(self, game.player)
	_cooldown = 1.5
	state.enter()
	_teleport(TofuFactory.HALL_ARRIVAL)
	if puzzle_enabled: DungeonRunActions.toggle_journal(self)
	else: game.hud.announce("Tofu Dungeon · [E] use stations")

func _exit() -> void:
	_inside = false
	DungeonMembership.exit(self, game.player)
	_carrying.erase(game.player)
	factory.show_cargo(cargo_positions())
	_cooldown = 2.0
	_teleport(TofuFactory.EAST_ENTRANCE + Vector3(-2.5, 0, 0))
	game.hud.announce("Tofu Factory · %s" % ("Refinement unlocked" if state.completed else "Return when ready"))

func _teleport(at: Vector3) -> void:
	_teleport_actor(game.player, at)

func _teleport_actor(actor: Player, at: Vector3) -> void:
	actor.relocate(at)
	actor.velocity = Vector3.ZERO
	if actor == game.player:
		game.camera.global_position = at + game.camera.offset
		game.combat.reset()

func _spawn_stage() -> void:
	DungeonStage.spawn_stage(self)

func _enemy_attack(amount: float, source: Vector3) -> void:
	DungeonStage.enemy_attack(self, amount, source)

func _enemy_spray(amount: float, source: Vector3, victim: Node3D) -> void:
	DungeonStage.enemy_spray(self, amount, source, victim)

func _enemy_defeated(_at: Vector3, enemy: FactoryBean) -> void:
	DungeonStage.enemy_defeated(self, _at, enemy)

func _crate_broken(at: Vector3, crate: FactoryCrate, index: int) -> void:
	DungeonStage.crate_broken(self, at, crate, index)

func _nearest_actor(at: Vector3) -> Node3D:
	return DungeonStage.nearest_actor(self, at)

func _nearest_member(at: Vector3) -> CoopActor:
	return DungeonStage.nearest_member(self, at)

func _register_target(target: Damageable) -> void:
	DungeonStage.register_target(self, target)

func _unregister_target(target: Damageable) -> void:
	DungeonStage.unregister_target(self, target)

func _sync_unlock() -> void:
	if game == null or game.inventory == null: return
	game.inventory.refining_unlocked = rewards.refinery_unlocked("solo") if not cooperative else false
	for key: String in party:
		party[key].inventory.refining_unlocked = rewards.refinery_unlocked(key)
	if game.inventory_window != null: game.inventory_window.refresh()

func capture() -> Dictionary:
	return DungeonPersistence.capture(self)

func capture_world() -> Dictionary:
	return TofuDungeonReplica.capture(self)

func apply_world(data: Dictionary) -> void:
	TofuDungeonReplica.apply(self, data)

func restore(data: Dictionary) -> void:
	DungeonPersistence.restore(self, data)

func _connect_actor(actor: Player) -> void:
	DungeonInteraction.connect_actor(self, actor)

func _command(command: PlayerCommand, _delta: float, actor: Player) -> void:
	DungeonInteraction.command(self, command, _delta, actor)

func interact(actor: Player) -> bool:
	return puzzle_flow.interact(self, actor) if puzzle_enabled else DungeonInteraction.interact(self, actor)

func submit_puzzle(command: TofuPuzzleCommand, actor: Player) -> Dictionary:
	return puzzle_flow.submit(self, command, actor)

func _puzzle_view_command(command: TofuPuzzleCommand) -> void:
	if enabled:
		var result: Dictionary = submit_puzzle(command, game.player)
		DungeonPuzzleViewFeedback.present(self, command, result)
	else: puzzle_command_requested.emit(command)

func cargo_positions() -> Array:
	return DungeonInteraction.cargo_positions(self)

func actor_in_run(actor: Player) -> bool:
	return DungeonMembership.contains(self, actor)
