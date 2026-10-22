class_name Order
extends RefCounted

# A single instruction issued by the AI commander to the worker.
# The worker obeys the current order unless the human player overrides it.

enum Type { IDLE, GATHER_GOLD, GATHER_WOOD, BUILD, ATTACK, DEFEND, REPAIR, MOVE }

var type: Type = Type.IDLE
var target: Node = null
var position: Vector3 = Vector3.ZERO
var building_type: String = ""
var reason: String = ""

func _init(p_type := Type.IDLE, p_target: Node = null, p_position := Vector3.ZERO, p_building_type := "") -> void:
	type = p_type
	target = p_target
	position = p_position
	building_type = p_building_type

func describe() -> String:
	match type:
		Type.GATHER_GOLD:
			return "Récolter de l'or"
		Type.GATHER_WOOD:
			return "Couper du bois"
		Type.BUILD:
			return "Construire : %s" % GameData.building_name(building_type)
		Type.ATTACK:
			return "Attaquer"
		Type.DEFEND:
			return "Défendre la base"
		Type.REPAIR:
			return "Réparer"
		Type.MOVE:
			return "Se déplacer"
		_:
			return "Inactif"
