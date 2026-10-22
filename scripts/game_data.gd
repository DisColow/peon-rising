class_name GameData
extends Object

# Static game data: resource keys, teams, building definitions and the color palette.

const GOLD := "gold"
const WOOD := "wood"
const FOOD := "food"

const TEAM_PLAYER := "player"
const TEAM_ENEMY := "enemy"

const BUILDINGS := {
	"town_hall": {
		"name": "Hôtel de ville",
		"gold": 0, "wood": 0, "hp": 1200, "food": 10,
		"scale": Vector3(4.2, 3.2, 4.2),
		"color": Color(0.82, 0.68, 0.45),
	},
	"farm": {
		"name": "Ferme",
		"gold": 15, "wood": 55, "hp": 380, "food": 8,
		"scale": Vector3(2.0, 1.6, 2.0),
		"color": Color(0.58, 0.44, 0.27),
	},
	"barracks": {
		"name": "Caserne",
		"gold": 60, "wood": 75, "hp": 800, "food": 0,
		"scale": Vector3(3.0, 2.4, 3.0),
		"color": Color(0.52, 0.48, 0.42),
	},
	"tower": {
		"name": "Tour de garde",
		"gold": 35, "wood": 45, "hp": 500, "food": 0,
		"scale": Vector3(1.6, 3.6, 1.6),
		"color": Color(0.62, 0.6, 0.52),
	},
}

const COLOR_GRASS := Color(0.36, 0.58, 0.26)
const COLOR_GROUND := Color(0.32, 0.52, 0.23)
const COLOR_PATH := Color(0.55, 0.48, 0.35)

const COLOR_PLAYER := Color(0.30, 0.66, 0.32)
const COLOR_PLAYER_SKIN := Color(0.55, 0.82, 0.45)
const COLOR_PLAYER_ARMOR := Color(0.35, 0.30, 0.26)

const COLOR_ENEMY := Color(0.76, 0.22, 0.20)
const COLOR_ENEMY_SKIN := Color(0.92, 0.52, 0.42)
const COLOR_ENEMY_ARMOR := Color(0.30, 0.22, 0.24)

const COLOR_TREE_TRUNK := Color(0.46, 0.33, 0.20)
const COLOR_TREE_LEAVES := Color(0.24, 0.54, 0.24)
const COLOR_TREE_LEAVES_DARK := Color(0.18, 0.42, 0.18)
const COLOR_GOLD := Color(1.0, 0.84, 0.20)
const COLOR_MINE := Color(0.40, 0.36, 0.44)
const COLOR_ROCK := Color(0.55, 0.55, 0.60)
const COLOR_WOOD_STACK := Color(0.65, 0.47, 0.26)

static func building_name(key: String) -> String:
	return BUILDINGS.get(key, {}).get("name", key)
