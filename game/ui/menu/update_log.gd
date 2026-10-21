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
	},
	{
		"id": 4, "date": "2026-10-19", "title": "Meadow skin testing",
		"bullets": [
			"Interact with the 3D Fufu display near Grandma to test seven Tofufu character skins.",
			"Try their standing, walking, jumping and melee poses, then switch back to Fufu at the display."
		]
	},
	{
		"id": 5, "date": "2026-10-19", "title": "Gigalopolis reaches the coast",
		"bullets": [
			"Explore a much larger Gigalopolis with matching city textures, market streets and stairways to rooftop camps and lookouts.",
			"Follow the new beach road from the city to Embercrown, then scout the volcano from the southern watchtower."
		]
	},
	{
		"id": 6, "date": "2026-10-19", "title": "Tofufu Royale arrives",
		"bullets": [
			"Battle Royale brings 20 survivors to the adventure map, with all seven Tofufu skins, scavenged gear and a closing storm.",
			"Find a peer match, invite friends with a private code or practise offline; CPUs fill the empty seats.",
			"Battle matches use equal starting stats and separate temporary gear, leaving your adventures untouched."
		]
	},
	{
		"id": 7, "date": "2026-10-20", "title": "Keep the Royale going",
		"bullets": [
			"If the Battle Royale host leaves, the match pauses while connected players choose a replacement and restore a shared checkpoint.",
			"Movement, combat and the storm stay paused during recovery; departed players become CPUs when play resumes.",
			"Tofufu animation frames stay centred, and Battle Royale walking faces the direction you move."
		]
	},
	{
		"id": 8, "date": "2026-10-20", "title": "Adventure combat in the Royale",
		"bullets": [
			"Battle Royale now uses adventure shooting, recoil, reloads, directional guarding, melee combos and weapon specials.",
			"Everyone starts with the same knife, soybean gun, health, armour and stamina; scavenged adventure weapons use match balance without saved levels or enhancements.",
			"Host recovery preserves ammunition, stamina, milk and special cooldowns, then clears unfinished attacks before play resumes."
		]
	},
	{
		"id": 9, "date": "2026-10-20", "title": "Loot, pack and survive",
		"bullets": [
			"Random chests are spread across the Battle Royale map, with the same chances of weapons, armour, backpacks and food everywhere.",
			"Choose nearby drops, manage your temporary backpack, wear matching armour sets and inspect your match stats.",
			"Soy Milk, apples and vegetables restore health during the match; eliminated survivors drop their gear, and host recovery preserves loot and healing."
		]
	},
	{
		"id": 10, "date": "2026-10-20", "title": "Choose your Royale rivals",
		"bullets": [
			"Choose 0–19 CPUs for Battle Royale, capped at 20 survivors with friends; smaller matches simulate fewer opponents.",
			"Pick Easy, Normal or Hard CPU reactions and aim, with equal health and damage; host recovery keeps the selected settings."
		]
	},
	{
		"id": 11, "date": "2026-10-20", "title": "A bigger Royale rumble",
		"bullets": [
			"Battle Royale now supports up to 50 CPUs alongside your friends, with Easy, Normal and Hard difficulty.",
			"Larger matches spread their starting positions, display the actual survivor total and preserve every fighter and item during host recovery."
		]
	},
	{
		"id": 12, "date": "2026-10-21", "title": "Sprout together in the Royale",
		"bullets": [
			"Choose a soybean plant before the Royale begins; rivals reserve different plants, and everyone emerges before combat starts.",
			"Play Duos with a friend against CPU teams, share a plant if you like, and win together with friendly damage disabled.",
			"Host recovery preserves plant reservations, the deployment countdown and your duo."
		]
	},
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
	}

]

static func latest_id() -> int:
	return int(ENTRIES.back().id) if not ENTRIES.is_empty() else 0

static func since(seen: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in ENTRIES:
		if int(entry.id) > seen: result.append(entry)
	return result
