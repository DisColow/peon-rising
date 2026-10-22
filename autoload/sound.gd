extends Node

# Lightweight one-shot sound manager. All sounds are tiny procedurally generated
# WAVs in assets/audio. Autoload singleton: `Sound`.

const SOUNDS := {
	"chop": "res://assets/audio/chop.wav",
	"mine": "res://assets/audio/mine.wav",
	"deposit": "res://assets/audio/deposit.wav",
	"build": "res://assets/audio/build.wav",
	"build_done": "res://assets/audio/build_done.wav",
	"hit": "res://assets/audio/hit.wav",
	"enemy_die": "res://assets/audio/enemy_die.wav",
	"hurt": "res://assets/audio/hurt.wav",
	"levelup": "res://assets/audio/levelup.wav",
	"victory": "res://assets/audio/victory.wav",
	"defeat": "res://assets/audio/defeat.wav",
	"click": "res://assets/audio/click.wav",
}

const POOL_SIZE := 12

var _streams: Dictionary = {}
var _players: Array = []

func _ready() -> void:
	for k in SOUNDS:
		_streams[k] = load(SOUNDS[k])
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play(sound_name: String, volume: float = 1.0) -> void:
	if not _streams.has(sound_name):
		return
	var p := _free_player()
	if p == null:
		return
	p.stream = _streams[sound_name]
	p.volume_db = linear_to_db(clampf(volume, 0.0, 1.0) * Settings.master_volume)
	p.pitch_scale = randf_range(0.94, 1.06)
	p.play()

func _free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]
