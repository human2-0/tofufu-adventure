class_name CoopQuests
extends Node
## Grandma's quests belong to each character; only authority counts kills and pays.

var session: CoopSession
var _sequence: int = 0
var _seen: Dictionary[String, int] = {}
var _pending: Dictionary[String, Array] = {}

func _ready() -> void:
	var giver: QuestGiver = session.game.quest_giver
	giver.request_action = request
	if session.game.encounters.mob_defeated.is_connected(giver._on_mob_defeated):
		session.game.encounters.mob_defeated.disconnect(giver._on_mob_defeated)
	if session.game.encounters.armored_snail_defeated.is_connected(giver.quest.record_armored_kill):
		session.game.encounters.armored_snail_defeated.disconnect(giver.quest.record_armored_kill)
	session.game.encounters.mob_defeated.connect(_kill)
	session.game.encounters.armored_snail_defeated.connect(_armored_kill)
	session.room.gameplay_packet.connect(_packet)
	session.roster.changed.connect(_departures)

func request(action: String, armored: bool) -> void:
	_sequence += 1
	var data := {"type": "grandma_quest", "sequence": _sequence, "action": action, "armored": armored}
	if session.authority: _packet(session.room.local_key, data)
	else: session.room.send_game(session.room.host_key, data)

func _packet(key: String, data: Dictionary) -> void:
	if not session.authority or data.get("type") != "grandma_quest": return
	if not session.roster.party.has(key) or not ExplorationProtocol.sequence(data.get("sequence")): return
	if data.sequence <= _seen.get(key, -1) or data.get("action") not in ["accept", "claim"] or not data.get("armored") is bool: return
	_seen[key] = int(data.sequence)
	if not _pending.has(key): _pending[key] = []
	if _pending[key].size() < 8: _pending[key].append(data.duplicate())

func _physics_process(_delta: float) -> void:
	if not session.authority: return
	for key: String in _pending:
		if not session.roster.party.has(key): continue
		var member: CoopActor = session.roster.party[key]
		if member.spectating or session.opening.active() or session.duel.is_participant(key): continue
		if not session.game.quest_giver.nearby(member.actor): continue
		for data: Dictionary in _pending[key]: _apply(member, data.action, data.armored)
	_pending.clear()

func _apply(member: CoopActor, action: String, armored: bool) -> void:
	if action == "accept":
		if armored: member.quests.start_armored()
		else: member.quests.start()
		return
	if armored:
		if not member.quests.claim_armored(member.inventory.count_item("piece_of_shell")): return
		member.inventory.remove_item("piece_of_shell", 10)
		_grant(member, InventoryItem.currency("mature_bean"), 20)
		member.progression.progress.award_experience(1000)
	elif member.quests.claim_reward():
		_grant(member, InventoryItem.create_edamame(), member.quests.reward_edamame)

func _grant(member: CoopActor, item: InventoryItem, count: int) -> void:
	var leftover := member.inventory.add_item(item, count)
	if leftover > 0: member.inventory.pending_items.append(ItemStack.new(item, leftover))

func _kill(_at: Vector3) -> void:
	if not session.authority: return
	for member: CoopActor in session.roster.party.values():
		if not member.spectating and not session.duel.is_participant(session.roster.actor_identity(member.actor)): member.quests.record_kill()

func _armored_kill() -> void:
	if not session.authority: return
	for member: CoopActor in session.roster.party.values():
		if not member.spectating and not session.duel.is_participant(session.roster.actor_identity(member.actor)): member.quests.record_armored_kill()

func _departures() -> void:
	for key: String in _seen.keys():
		if session.roster.party.has(key): continue
		_seen.erase(key)
		_pending.erase(key)
