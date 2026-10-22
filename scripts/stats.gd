class_name Stats
extends Object

# Builds the effective stat block for a worker from its base stats,
# the unlocked roguelite talents and the permanent meta bonuses.

const BASE := {
	"chop_speed": 1.0,
	"chop_yield": 1.0,
	"mine_speed": 1.0,
	"mine_yield": 1.0,
	"carry_capacity": 10.0,
	"carry_speed": 1.0,
	"build_speed": 1.0,
	"repair_speed": 1.0,
	"build_discount": 0.0,
	"max_hp": 100.0,
	"damage": 12.0,
	"move_speed": 1.0,
	"armor": 0.0,
	"attack_speed": 1.0,
	"dodge": 0.0,
}

static func compute(unlocked_talents: Array) -> Dictionary:
	var s := BASE.duplicate(true)
	for t in unlocked_talents:
		var node := TalentDB.node(t[0], t[1])
		if node.is_empty():
			continue
		var stat: String = node["stat"]
		s[stat] = TalentDB.apply(stat, node["value"], node["kind"], s[stat])

	var b := Meta.bonus_stats()
	s["max_hp"] += b["max_hp_bonus"]
	s["damage"] += b["damage_bonus"]
	s["move_speed"] += b["move_speed_bonus"]
	s["carry_capacity"] += b["carry_bonus"]
	s["build_speed"] += b["build_speed_bonus"]
	s["dodge"] += b["dodge_bonus"]

	# Guard rail against degenerate values.
	s["armor"] = clampf(s["armor"], 0.0, 0.8)
	s["dodge"] = clampf(s["dodge"], 0.0, 0.6)
	return s
