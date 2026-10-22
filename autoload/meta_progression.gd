extends Node

# Permanent progression between matches (the "meta" layer).
# Survives death and roguelite resets. Persisted to user:// as JSON.

const SAVE_PATH := "user://meta_save.json"

# Each key is an upgrade with a current level (0 = locked/unpurchased).
var meta := {
	"stamina": 0,        # +max HP per level
	"strength": 0,       # +flat damage per level
	"speed": 0,          # +move speed per level
	"economy": 0,        # +carry capacity per level
	"build_mastery": 0,  # +build speed per level
	"luck": 0,           # +dodge chance per level
}

# Currency earned at the end of each match, spent on permanent upgrades.
var essence: int = 0

func _ready() -> void:
	load_save()

func bonus_stats() -> Dictionary:
	return {
		"max_hp_bonus": float(meta["stamina"]) * 10.0,
		"damage_bonus": float(meta["strength"]) * 1.5,
		"move_speed_bonus": float(meta["speed"]) * 0.03,
		"carry_bonus": float(meta["economy"]) * 1.0,
		"build_speed_bonus": float(meta["build_mastery"]) * 0.04,
		"dodge_bonus": float(meta["luck"]) * 0.01,
	}

func upgrade_cost(key: String) -> int:
	if not meta.has(key):
		return 0
	return meta[key] + 1

func upgrade(key: String) -> bool:
	if not meta.has(key):
		return false
	var cost := upgrade_cost(key)
	if essence < cost:
		return false
	essence -= cost
	meta[key] += 1
	save_save()
	return true

func add_essence(amount: int) -> void:
	essence += amount
	save_save()

func save_save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"essence": essence, "meta": meta}))
		f.close()

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_DICTIONARY:
		essence = int(data.get("essence", 0))
		var m = data.get("meta", {})
		for k in meta.keys():
			meta[k] = int(m.get(k, 0))
