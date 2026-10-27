class_name UpdateLog
extends RefCounted
## Append release batches in ascending order. IDs remain stable after shipping.
## Each bullet is an exact English PO source; the panel shows both languages.

const RECENT: Array[Dictionary] = [
	{
		"id": 13, "date": "2026-10-21", "title": "Gigalopolis spreads east",
		"bullets": [
			"Gigalopolis now stretches east across the width of Embercrown, with connected avenues, planted squares and a wider shoreline.",
			"Explore new terraced homes, vaulted depots, workshops, market arcades, courtyard halls and towers with matching textures and more rooftop camps."
		]
	},
	{
		"id": 14, "date": "2026-10-21", "title": "Gigalopolis doors are open",
		"bullets": [
			"Walk into Gigalopolis homes, shops, workshops and civic buildings, with furnished rooms and roof cutaways.",
			"Discover 18 one-time supply chests with modest food, materials and occasional basic equipment. Opened chests and remaining loot persist in solo and co-op saves."
		]
	},
	{
		"id": 15, "date": "2026-10-21", "title": "Watch for nearby gunfire",
		"bullets": [
			"Nearby enemy shots leave a fading red dot on your Battle Royale map for two seconds within 100 metres; each dot stays at the shot's origin."
		]
	},
	{
		"id": 16, "date": "2026-10-21", "title": "One more Royale",
		"bullets": [
			"Royale storms now lead to different dry finale clearings, with next-circle previews, rotation guidance and clearer combat feedback.",
			"Complete looting, damage and survival goals, review your round and build a cosmetic Royale career with separate practice and peer records.",
			"Ready up for another round with your connected friends. Armour recovers between fights, and CPUs handle cover and regroup with their duo.",
			"Mark a route with G or danger with H; only your duo sees these brief callouts."
		]
	},
	{
		"id": 17, "date": "2026-10-21", "title": "Risk a Royale hunt",
		"bullets": [
			"Roaming snails, armored snails and wild bees now threaten Royale survivors and CPUs. Hunt them for guaranteed food and useful temporary gear.",
			"Hunts are spread across the map, never respawn during a round and survive paused host recovery without duplicating rewards."
		]
	},
	{
		"id": 18, "date": "2026-10-21", "title": "Meet Firm Tofufu",
		"bullets": [
			"The green-headband character is Firm Tofufu in the skin selector and Battle Royale."
		]
	},
	{
		"id": 19, "date": "2026-10-21", "title": "Royale hunts fight back",
		"bullets": [
			"Every Royale hunt can now fire a warned, dodgeable ranged attack. Cover, guard reflection and changing direction help you survive.",
			"Find Common, Rare and Legendary gear across the map. Weapons have distinct strengths, CPUs keep upgrading, and a complete Celestial set is the strongest loadout."
		]
	},
	{
		"id": 20, "date": "2026-10-22", "title": "Read the Royale at a glance",
		"bullets": [
			"A compact Royale HUD shows health, armour, stamina, weapons and food with icons and bars. Open Help for controls.",
			"Start behind Tofufu, press C for the overhead test view, and use middle click to rotate overhead or switch shoulders.",
			"A moving purple storm wall, bright ground edge and shaded map make danger clear. Follow the safe-zone arrow before the storm reaches you."
		]
	},
	{
		"id": 21, "date": "2026-10-22", "title": "Loot, withstand and rotate",
		"bullets": [
			"Defeated survivors drop their entire equipment and backpack contents, preserving remaining item resources.",
			"Incoming damage briefly pulses the screen edges red. Each partial armour piece has 50 durability and a quarter of its set modifiers; complete matching sets cannot break.",
			"Soybean plants, chests and storm finales now reach distant map regions. Early circles allow more time to travel, and eligible regions have equal finale chances."
		]
	},
	{
		"id": 22, "date": "2026-10-23", "title": "Faster shots, a lighter Royale",
		"bullets": [
			"Royale gun bullets fly 2.5 times faster, keeping their existing range, damage and reload balance.",
			"Open Graphics from the match menu to adjust resolution, scenery distance and shadows, or choose the Performance preset. Nearby combat and cover stay active.",
			"The update journal now has compact bilingual headlines and expandable details, with the newest release first."
		]
	},
	{
		"id": 23,
		"date": "2026-10-23",
		"title": "Scavenge, enhance, celebrate",
		"bullets": [
			"More Royale chests fill the map: basic, rare and crowned legendary designs, each with weapons, protection and food. Better tiers improve gear chances.",
			"Find Magical Tofufu Chunks with 10% / 35% / 70% chances by chest tier. Enhance each weapon once for this round: stronger, faster attacks, better guns or cheaper guard reflections.",
			"Round results now celebrate placement, achievements and cosmetic Royale levels with stat icons, reward tiles and an animated XP bar."
		]
	},
	{
		"id": 24, "date": "2026-10-23", "title": "Firmer footing",
		"bullets": [
			"Characters now start and turn more firmly, then ease smoothly to a stop. Ice keeps its slippery feel and airborne movement is unchanged."
		]
	},
	{
		"id": 25, "date": "2026-10-23", "title": "A very firm surprise",
		"bullets": [
			"Meet Honio Meniono, a rare Royale-only musclebound Tofufu. Dodge his warned melee rush and slam, punish his recovery and claim temporary gear, healing and a Magical Tofufu Chunk."
		]
	},
	{
		"id": 26, "date": "2026-10-23", "title": "Arrows that make an impression",
		"bullets": [
			"Bow arrows now leave visible trails. Hold RMB for 1.25 seconds to launch a flame arrow, with charge feedback at the reticle and bursts on enemies, terrain and cover.",
			"Royale melee weapons have clearer power and speed differences: heavy Pod Sword hits, quick Katana combos and deliberate staff sweeps. Legendary weapons improve their families; item details show base damage and attack time.",
			"Chests leave more room beside deployment plants, keeping soybean emergence clear."
		]
	},
	{
		"id": 27, "date": "2026-10-27", "title": "Your Royale view",
		"bullets": [
			"Change window resolution and fullscreen from the Royale Graphics menu. Keep your display choice or let it revert automatically after 15 seconds."
		]
	},
	{
		"id": 28, "date": "2026-10-27", "title": "Smoother journeys and Royale",
		"bullets": [
			"Royale storms and CPU matches do less work each frame, reducing hitches while keeping the same combat and storm timing.",
			"Smaller matches now save work on offscreen survivors and landing shadows too. Terrain and city cutaways avoid repeated updates while preserving the scenery."
		]
	}

]

static func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(UpdateLogArchive.ENTRIES)
	result.append_array(RECENT)
	return result

static func latest_id() -> int:
	var batches := entries()
	return int(batches.back().id) if not batches.is_empty() else 0

static func since(seen: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries():
		if int(entry.id) > seen: result.append(entry)
	return result
