extends Resource
class_name AbilityEffect


func on_enter(_battler: Battler) -> void:
	pass


func on_switch_in(_battler: Battler) -> void:
	pass


func on_hit(_battler: Battler, _target: Battler, _move: MoveData) -> void:
	pass


func on_hit_by(_battler: Battler, _attacker: Battler, _move: MoveData) -> void:
	pass


func on_faint(_battler: Battler) -> void:
	pass


func on_stat_change(_battler: Battler, _stat: String, _stages: int) -> Dictionary:
	return {}


func on_status_inflicted(_battler: Battler, _status: String) -> void:
	pass


func on_weather(_battler: Battler, _weather: Variant) -> void:
	pass


func on_terrain(_battler: Battler, _terrain: Variant) -> void:
	pass
