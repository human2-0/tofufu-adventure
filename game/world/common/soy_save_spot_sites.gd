class_name SoySaveSpotSites
extends RefCounted
## Append-only personal checkpoint IDs; never reorder the saved ownership bits.

const IDS: Array[String] = ["nursery", "village", "desert", "shore", "frost", "factory", "jungle", "clouds", "embercrown", "dofufu", "groatfields"]
const TITLES: Array[String] = ["Nursery Roots", "Fufufarm Village", "Sunsand Oasis", "Northern Shore", "Frostcrown Reach", "Gigalopolis Gate", "Jadewild Landing", "Cloud Sanctuary", "Embercrown Landing", "Dofufu Gate", "Groatfields Approach"]
const POINTS: Array[Vector2] = [Vector2(-1, -2.5), Vector2(35, -14), Vector2(4, 118), Vector2(4, -76), Vector2(4, -250), Vector2(92, 6), Vector2(-1, 232), Vector2(-2, 250), Vector2(239, 318), Vector2(-840, 5), Vector2(4, 348)]
