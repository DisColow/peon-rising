extends Node

# Central signal bus. Keeps the commander, worker, buildings, enemies and UI
# decoupled — which also makes the future multiplayer split easier (the bus can
# be mirrored over the network).

signal order_assigned(order)
signal order_progress_changed(order, progress)
signal order_completed(order)
signal order_cancelled(order)

signal worker_hp_changed(current: float, maximum: float)
signal worker_died()
signal worker_respawned()

signal resource_changed(gold: int, wood: int, food_used: int, food_max: int)
signal xp_changed(current: int, needed: int, level: int)
signal talent_point_gained(points: int)
signal talent_unlocked(tree: String, talent_id: String)

signal influence_changed(current: float, maximum: float)
signal toast(message: String)

signal building_completed(building)
signal building_damaged(building)
signal base_destroyed(team: String)
signal enemy_killed(enemy)
signal match_ended(victory: bool)
