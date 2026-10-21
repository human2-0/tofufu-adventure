class_name BattleElection
extends RefCounted
## One bounded ballot at a time. Votes/readiness are authenticated peer messages.

var blob: String = ""
var digest: String = ""
var votes: Dictionary = {}
var ready: Dictionary = {}
var committed: bool = false
var countdown: float = -1
var active: Array = []

func clear() -> void:
	blob = ""
	digest = ""
	votes.clear()
	ready.clear()
	committed = false
	countdown = -1
	active.clear()

func receive(m: BattleMigration, key: String, packet: Dictionary) -> void:
	match packet.kind:
		"br_mproposal":
			if key != m.candidate() or not blob.is_empty(): return
			var state := BattleCheckpoint.decode(packet.get("blob"), m.room.members)
			if state.is_empty() or state.options != m.room.options or not state.voters.has(m.failed_host): return
			blob = packet.blob
			digest = blob.sha256_text()
		"br_mvote":
			if packet.get("digest") == digest and not digest.is_empty(): votes[key] = true
		"br_mcommit":
			if key != m.candidate() or packet.get("digest") != digest or digest.is_empty(): return
			if votes.size() < m.quorum() or not votes.has(m.candidate()) or committed: return
			committed = true
			m.checkpoint = blob
			m.checkpoint_seq = int(BattleCheckpoint.decode(blob, m.room.members).seq)
			m.room.status = "Match paused · Restoring the shared checkpoint"
			m.restoring.emit(BattleCheckpoint.decode(blob, m.room.members))
		"br_mready":
			if packet.get("digest") == digest and not digest.is_empty(): ready[key] = true
		"br_mgo":
			if key != m.candidate() or not committed or packet.get("digest") != digest or countdown >= 0: return
			var value: Variant = packet.get("active")
			if not value is Array or value.size() < m.quorum() or value.size() > m.candidates.size() or not value.has(key): return
			var seen: Dictionary = {}
			for member: Variant in value:
				if not member is String or not ready.has(member) or seen.has(member): return
				seen[member] = true
			active = value.duplicate()
			countdown = m.room.clock + 1.5
			m.room.status = "New host found · Resuming shortly"

func repeat(m: BattleMigration) -> void:
	if not blob.is_empty():
		if m.room.local_key == m.candidate(): m.cast("br_mproposal", {"blob": blob})
		var choice := m.candidate() + digest
		if m.vote_lock.is_empty(): m.vote_lock = choice
		# A peer never votes for competing replacements during this host-loss episode.
		if m.candidates.has(m.room.local_key) and m.vote_lock == choice: m.cast("br_mvote", {"digest": digest})
	if committed and m.candidates.has(m.room.local_key): m.cast("br_mready", {"digest": digest})
	if m.room.local_key != m.candidate() or digest.is_empty(): return
	if votes.size() >= m.quorum(): m.cast("br_mcommit", {"digest": digest})
	if countdown >= 0: m.cast("br_mgo", {"digest": digest, "active": active})

func step(m: BattleMigration) -> void:
	if countdown >= 0:
		if m.room.clock >= countdown: m.complete(active)
		return
	if m.room.local_key != m.candidate(): return
	if blob.is_empty() and m.room.clock - m.since >= 0.65:
		var best: Dictionary = {}
		for value: Dictionary in m.offers.values():
			if best.is_empty() or int(value.seq) > int(best.seq): best = value
		if not best.is_empty(): m.cast("br_mproposal", {"blob": best.blob})
	if committed and ready.size() >= m.quorum() and ready.has(m.room.local_key):
		# Give every reachable survivor a chance to load before sealing CPU replacements.
		if ready.size() == m.candidates.size() or m.room.clock - m.since >= 2:
			var available := ready.keys()
			available.sort()
			m.cast("br_mgo", {"digest": digest, "active": available})
