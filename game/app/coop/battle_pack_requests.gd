class_name BattlePackRequests
extends RefCounted
## Authenticated intents share the host's minimum delay and are rechecked at commit.
var pack: BattlePack
var sequence: int = 0
var seen: Dictionary = {}
var queue: Array = []
var replies: Dictionary = {}

func request(action: int, args: Array) -> void:
	sequence += 1
	var game := pack.game
	var packet := {"kind": "br_pack", "epoch": game.room.epoch, "term": game.room.term, "seq": sequence,
		"action": action, "args": args, "revision": pack.revisions[game.local_slot]}
	if game.room.authority(): receive(game.room.local_key, packet)
	else: game.room.send(game.room.host_key, packet)

func receive(key: String, packet: Dictionary) -> void:
	var game := pack.game
	if not game.room.authority() or packet.get("epoch") != game.room.epoch or packet.get("term") != game.room.term: return
	if game.deployment.active(): return
	if not BattleProtocol.integer(packet.get("seq"), 1, 2147483647) or int(packet.seq) <= int(seen.get(key, 0)): return
	if int(packet.seq) > int(seen.get(key, 0)) + 240 or not BattleProtocol.integer(packet.get("revision"), 0, 1000000): return
	if not BattleProtocol.integer(packet.get("action"), 0, 4) or not packet.get("args") is Array: return
	var args: Array = packet.args
	var lengths: Array[int] = [1, 1, 4, 2, 2]
	if args.size() != lengths[int(packet.action)]: return
	for value in args:
		if not BattleProtocol.integer(value, 0, 1000000): return
	var slot := -1
	for i in game.room.members.size():
		if game.room.members[i].key == key: slot = i
	if slot < 0 or game.match_state.rows[slot][17] != 0 or queue.size() >= 80: return
	var waiting := 0
	for entry: Array in queue:
		if int(entry[1]) == slot: waiting += 1
	if waiting >= 4: return
	seen[key] = int(packet.seq)
	queue.append([game.simulation.clock + BattleProtocol.INPUT_DELAY, slot, packet.duplicate(true)])

func flush(now: float, rotation: int) -> void:
	for offset in pack.game.bodies.size():
		var slot := (rotation + offset) % pack.game.bodies.size()
		for entry: Array in queue.duplicate():
			if int(entry[1]) != slot or float(entry[0]) > now: continue
			queue.erase(entry)
			var packet: Dictionary = entry[2]
			var success := apply(slot, int(packet.action), packet.args, int(packet.revision))
			var result := {"kind": "br_pack_result", "epoch": pack.game.room.epoch, "term": pack.game.room.term, "seq": packet.seq, "ok": success}
			if slot == pack.game.local_slot:
				if replies.size() >= 32: replies.erase(replies.keys()[0])
				replies[int(packet.seq)] = success
			else: pack.game.room.send(pack.game.room.members[slot].key, result)

func apply(slot: int, action: int, args: Array, revision: int) -> bool:
	var game := pack.game
	if not game.room.authority() or not game.playing or game.match_state.time < BattleRing.GRACE or game.match_state.winner != -2 or game.match_state.rows[slot][8] <= 0: return false
	if action >= 2 and revision != pack.revisions[slot]: return false
	match action:
		0: return BattleChestLoot.open(pack, slot, int(args[0]))
		1: return pack.transactions.take(slot, int(args[0]))
		2:
			if args[0] > 1 or args[2] > 1 or args[1] > 19 or args[3] > 19: return false
			return pack.transactions.transfer(slot, args[0], args[1], args[2], args[3])
		3, 4:
			if args[0] > 1 or args[1] > (19 if args[0] == 0 else 11): return false
			return pack.transactions.consume(slot, args[0], args[1]) if action == 3 else pack.transactions.drop(slot, args[0], args[1])
	return false

func clear() -> void:
	sequence = 0
	seen.clear()
	queue.clear()
	replies.clear()
