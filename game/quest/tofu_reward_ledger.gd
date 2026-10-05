class_name TofuRewardLedger
extends RefCounted
## Trusted-host reward decisions for stable encounter slots across attempts.

const VERSION: int = 1
const MAX_SLOTS: int = 8
const MAX_MEMBERS: int = 64
const ORDINARY_EXP: int = 65
const BOSS_EXP: int = 250

var _paid: Dictionary = {}
var _entitled: Dictionary = {}

static func slot_id(encounter: String, slot: int) -> String:
	if not valid_encounter(encounter) or slot < 0 or slot >= MAX_SLOTS: return ""
	if encounter == "dofufu_boss" and slot != 0: return ""
	return "%s_slot_%02d" % [encounter, slot]

static func valid_encounter(encounter: String) -> bool:
	if encounter in ["lab_opening", "lab_curd", "dofufu_boss"]: return true
	if encounter.begins_with("penalty_") and encounter.length() == 10:
		var number: String = encounter.substr(8, 2)
		return number.is_valid_int() and int(number) >= 1 and int(number) <= TofuPuzzleContract.MAX_MISTAKES and encounter == "penalty_%02d" % int(number)
	if encounter.begins_with("stage_") and encounter.length() == 8:
		var stage: String = encounter.substr(6, 2)
		return stage.is_valid_int() and int(stage) >= 0 and int(stage) <= 5 and encounter == "stage_%02d" % int(stage)
	return false

func claim_confirmed_defeat(encounter: String, slot: int) -> Dictionary:
	var identity: String = slot_id(encounter, slot)
	if identity.is_empty() or encounter == "dofufu_boss": return {"valid": false}
	if _paid.has(identity):
		return {"valid": true, "practice": true, "label": "Practice encounter — reward already claimed.",
			"identity": identity, "item_id": "", "count": 0, "experience": 0}
	_paid[identity] = true
	return {"valid": true, "practice": false, "label": "", "identity": identity,
		"item_id": "edamame", "count": 10, "experience": ORDINARY_EXP}

func complete_confirmed_boss(members: Array[String]) -> Dictionary:
	if members.is_empty() or members.size() > MAX_MEMBERS: return {"valid": false}
	for member: String in members:
		if not _valid_member(member): return {"valid": false}
	for member: String in members: _entitled[member] = true
	var identity: String = slot_id("dofufu_boss", 0)
	if _paid.has(identity):
		return {"valid": true, "practice": true, "label": "Practice encounter — reward already claimed.",
			"identity": identity, "item_id": "", "count": 0, "experience": 0}
	_paid[identity] = true
	return {"valid": true, "practice": false, "label": "", "identity": identity,
		"item_id": "mature_bean", "count": 10, "experience": BOSS_EXP}

func refinery_unlocked(member: String) -> bool:
	return _entitled.has(member)

func reward_available(encounter: String, slot: int) -> bool:
	var identity: String = slot_id(encounter, slot)
	return not identity.is_empty() and not _paid.has(identity)

func capture() -> Dictionary:
	var paid: Array[String] = []
	var entitled: Array[String] = []
	for identity: String in _paid: paid.append(identity)
	for member: String in _entitled: entitled.append(member)
	paid.sort()
	entitled.sort()
	return {"version": VERSION, "paid": paid, "entitled": entitled}

func restore(data: Dictionary) -> bool:
	if data.get("version") != VERSION: return false
	var paid_value: Variant = data.get("paid")
	var entitled_value: Variant = data.get("entitled")
	if not paid_value is Array or not entitled_value is Array: return false
	if paid_value.size() > 21 * MAX_SLOTS or entitled_value.size() > MAX_MEMBERS: return false
	var next_paid: Dictionary = {}
	var next_entitled: Dictionary = {}
	for value: Variant in paid_value:
		if not value is String or not _valid_slot_id(value) or next_paid.has(value): return false
		next_paid[value] = true
	for value: Variant in entitled_value:
		if not value is String or not _valid_member(value) or next_entitled.has(value): return false
		next_entitled[value] = true
	_paid = next_paid
	_entitled = next_entitled
	return true

static func _valid_slot_id(identity: String) -> bool:
	if identity.length() < 13 or identity.length() > 19: return false
	var parts: PackedStringArray = identity.rsplit("_slot_", true, 1)
	if parts.size() != 2 or parts[1].length() != 2 or not parts[1].is_valid_int(): return false
	return identity == slot_id(parts[0], int(parts[1]))

static func _valid_member(member: String) -> bool:
	if member.is_empty() or member.length() > 64: return false
	for index in member.length():
		var code: int = member.unicode_at(index)
		if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90)
			or (code >= 97 and code <= 122) or code in [45, 46, 58, 95]): return false
	return true
