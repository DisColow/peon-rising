extends Node

# Player settings, persisted to user://settings.json. Autoload: `Settings`.

const SAVE_PATH := "user://settings.json"

var mouse_sensitivity: float = 1.0
var master_volume: float = 0.8

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"mouse_sensitivity": mouse_sensitivity, "master_volume": master_volume}))
		f.close()

func load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_DICTIONARY:
		mouse_sensitivity = float(data.get("mouse_sensitivity", 1.0))
		master_volume = float(data.get("master_volume", 0.8))
