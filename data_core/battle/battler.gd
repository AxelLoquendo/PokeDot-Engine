extends Node
class_name Battler

## API de habilidades. El combate usa BattleBattler, no esta clase.

@export var ability: AbilityData = null
var ability_active: bool = true


func set_ability(value: AbilityData) -> void:
	ability = value
	ability_active = ability != null


func clear_ability() -> void:
	ability = null
	ability_active = false


func get_ability_effect() -> AbilityEffect:
	if ability == null or not ability_active:
		return null
	return ability.behavior


func trigger_ability_enter() -> void:
	if ability == null or not ability_active or not ability.triggers_on_enter:
		return
	var effect: AbilityEffect = get_ability_effect()
	if effect:
		effect.on_enter(self)


func trigger_ability_switch_in() -> void:
	if ability == null or not ability_active or not ability.triggers_on_switch_in:
		return
	var effect: AbilityEffect = get_ability_effect()
	if effect:
		effect.on_switch_in(self)


func trigger_ability_hit(target: Battler, move: MoveData) -> void:
	if ability == null or not ability_active or not ability.triggers_on_hit:
		return
	var effect: AbilityEffect = get_ability_effect()
	if effect:
		effect.on_hit(self, target, move)


func trigger_ability_hit_by(attacker: Battler, move: MoveData) -> void:
	if ability == null or not ability_active or not ability.triggers_on_hit_by:
		return
	var effect: AbilityEffect = get_ability_effect()
	if effect:
		effect.on_hit_by(self, attacker, move)


func trigger_ability_faint() -> void:
	if ability == null or not ability_active or not ability.triggers_on_faint:
		return
	var effect: AbilityEffect = get_ability_effect()
	if effect:
		effect.on_faint(self)


func trigger_ability_stat_change(stat: String, stages: int) -> Dictionary:
	if ability == null or not ability_active or not ability.triggers_on_stat_change:
		return {}
	var effect: AbilityEffect = get_ability_effect()
	if effect == null:
		return {}
	return effect.on_stat_change(self, stat, stages)


func trigger_ability_status(status: String) -> void:
	if ability == null or not ability_active or not ability.triggers_on_status:
		return
	var effect: AbilityEffect = get_ability_effect()
	if effect:
		effect.on_status_inflicted(self, status)


func trigger_ability_weather(weather: Variant) -> void:
	if ability == null or not ability_active or not ability.triggers_on_weather:
		return
	var effect: AbilityEffect = get_ability_effect()
	if effect:
		effect.on_weather(self, weather)


func trigger_ability_terrain(terrain: Variant) -> void:
	if ability == null or not ability_active or not ability.triggers_on_terrain:
		return
	var effect: AbilityEffect = get_ability_effect()
	if effect:
		effect.on_terrain(self, terrain)
