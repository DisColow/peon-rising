extends Node

# The enemy commander: spawns escalating waves of grunts that march on the
# player base. Kept simple so the focus stays on the player's own worker.

var base: Node = null
var player_base: Node = null
var spawn_parent: Node = null

var _wave_timer: float = 14.0
var _time: float = 0.0

const GRUNT := preload("res://scenes/units/grunt.gd")

func setup(p_base: Node, p_player_base: Node, p_spawn_parent: Node) -> void:
	base = p_base
	player_base = p_player_base
	spawn_parent = p_spawn_parent

func _process(delta: float) -> void:
	if not GameState.match_running:
		return
	_time += delta
	_wave_timer -= delta
	if _wave_timer <= 0.0:
		_spawn_wave()
		_wave_timer = maxf(6.0, 16.0 - _time * 0.06)

func _spawn_wave() -> void:
	var count := 1 + int(_time / 45.0)
	count = mini(count, 6)
	for i in count:
		_spawn_grunt()

func _spawn_grunt() -> void:
	if spawn_parent == null:
		return
	var g = GRUNT.new()
	g.team = GameData.TEAM_ENEMY
	g.max_hp = 70.0 + _time * 2.5
	g.attack_damage = 8.0 + _time * 0.25
	g.move_speed = 3.4 + minf(1.2, _time * 0.012)
	g.attack_cooldown = 1.2
	g.attack_mode = "seek_base"
	g.target_position = (player_base as Node3D).global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
	spawn_parent.add_child(g)
	g.global_position = (base as Node3D).global_position + Vector3(randf_range(-3, 3), 0.5, randf_range(2, 4))
