class_name TalentDB
extends Object

# The three roguelite talent trees. Unlocks are reset on death, so the player
# re-specializes every "run" (life of a single worker).

const TREES := {
	"harvest": {
		"name": "Récolte",
		"color": Color(0.40, 0.80, 0.30),
		"nodes": [
			{"id": "chop_1", "name": "Bûcheron", "desc": "+20% vitesse de coupe", "stat": "chop_speed", "value": 0.20, "kind": "mult"},
			{"id": "chop_2", "name": "Déboiseur", "desc": "+15% de bois par coupe", "stat": "chop_yield", "value": 0.15, "kind": "mult"},
			{"id": "mine_1", "name": "Mineur", "desc": "+20% vitesse de minage", "stat": "mine_speed", "value": 0.20, "kind": "mult"},
			{"id": "mine_2", "name": "Prospecteur", "desc": "+15% d'or par extraction", "stat": "mine_yield", "value": 0.15, "kind": "mult"},
			{"id": "carry_1", "name": "Porteur", "desc": "+2 capacité de transport", "stat": "carry_capacity", "value": 2.0, "kind": "add"},
			{"id": "carry_2", "name": "Bête de somme", "desc": "+15% vitesse en transportant", "stat": "carry_speed", "value": 0.15, "kind": "mult"},
		],
	},
	"build": {
		"name": "Construction",
		"color": Color(0.90, 0.75, 0.25),
		"nodes": [
			{"id": "builder_1", "name": "Maçon", "desc": "+20% vitesse de construction", "stat": "build_speed", "value": 0.20, "kind": "mult"},
			{"id": "builder_2", "name": "Architecte", "desc": "+20% vitesse de construction", "stat": "build_speed", "value": 0.20, "kind": "mult"},
			{"id": "repair_1", "name": "Réparateur", "desc": "+30% vitesse de réparation", "stat": "repair_speed", "value": 0.30, "kind": "mult"},
			{"id": "cheap_1", "name": "Économe", "desc": "-15% de coût de construction", "stat": "build_discount", "value": 0.15, "kind": "add"},
		],
	},
	"combat": {
		"name": "Combat",
		"color": Color(0.90, 0.30, 0.25),
		"nodes": [
			{"id": "hp_1", "name": "Robuste", "desc": "+30 PV max", "stat": "max_hp", "value": 30.0, "kind": "add"},
			{"id": "dmg_1", "name": "Cogneur", "desc": "+20% dégâts", "stat": "damage", "value": 0.20, "kind": "mult"},
			{"id": "speed_1", "name": "Rapide", "desc": "+12% vitesse de déplacement", "stat": "move_speed", "value": 0.12, "kind": "mult"},
			{"id": "armor_1", "name": "Résistant", "desc": "-15% dégâts subis", "stat": "armor", "value": 0.15, "kind": "add"},
			{"id": "aspeed_1", "name": "Vif", "desc": "+20% vitesse d'attaque", "stat": "attack_speed", "value": 0.20, "kind": "mult"},
			{"id": "dodge_1", "name": "Agile", "desc": "+10% d'esquive", "stat": "dodge", "value": 0.10, "kind": "add"},
		],
	},
}

static func tree_ids() -> Array:
	return TREES.keys()

static func tree_name(tree: String) -> String:
	return TREES.get(tree, {}).get("name", tree)

static func nodes_in(tree: String) -> Array:
	return TREES.get(tree, {}).get("nodes", [])

static func node(tree: String, id: String) -> Dictionary:
	for n in nodes_in(tree):
		if n["id"] == id:
			return n
	return {}

static func apply(stat: String, value: float, kind: String, base: float) -> float:
	if kind == "add":
		return base + value
	return base * (1.0 + value)
