class_name UpdateLog
extends RefCounted
## Append release batches in ascending order. IDs remain stable after shipping.
## Each bullet is an exact English PO source; the panel shows both languages.

const ENTRIES: Array[Dictionary] = [
	{
		"id": 1, "date": "2026-10-17", "title": "Adventure playtest",
		"bullets": [
			"New combat gear: Fallen Angel Bow, Bengal Paws and Soy Milk.",
			"Stronger character growth, clearer stats and a celebration when you level up.",
			"More places to explore, personal soybean save spots to claim and a Dofufu solo challenge.",
			"Updated character art, scenery and terrain, plus more graphics options.",
			"Improvements to co-op, saves and combat controls."
		]
	},
	{
		"id": 2, "date": "2026-10-17", "title": "Your update journal",
		"bullets": [
			"A short English and Polish update journal now shows what changed since your last visit.",
			"Reopen the journal any time from the title or pause menu."
		]
	},
	{
		"id": 3, "date": "2026-10-17", "title": "Smoother adventuring",
		"bullets": [
			"Super Claw dashes and Nori plunges keep working after solo and co-op arena matches.",
			"In the behind-the-player view, stopping now keeps Fufu facing the direction you were walking."
		]
	}
]

static func latest_id() -> int:
	return int(ENTRIES.back().id) if not ENTRIES.is_empty() else 0

static func since(seen: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in ENTRIES:
		if int(entry.id) > seen: result.append(entry)
	return result
