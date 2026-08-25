extends RefCounted

class_name EvolutionMigrator

## Convierte una regla legacy a la representación nueva sin tocar el .tres original.
static func convert_rule(legacy: EvolutionData) -> EvolutionData:
	if legacy == null:
		return null
	if legacy.is_advanced_rule():
		return legacy.duplicate_rule()

	var result: EvolutionData = legacy.duplicate_rule()
	result.use_advanced_rules = true
	result.conditions.clear()

	match legacy.method:
		PokemonData.EvolutionMethods.EVO_LEVEL:
			result.trigger = EvolutionTrigger.Trigger.LEVEL_UP
			var level: EvolutionConditionLevel = EvolutionConditionLevel.new()
			level.minimum_level = legacy.parameter
			result.conditions.append(level)
		PokemonData.EvolutionMethods.EVO_LEVEL_BATTLE_ONLY:
			result.trigger = EvolutionTrigger.Trigger.LEVEL_UP_BATTLE_ONLY
			var battle_level: EvolutionConditionLevel = EvolutionConditionLevel.new()
			battle_level.minimum_level = legacy.parameter
			result.conditions.append(battle_level)
		PokemonData.EvolutionMethods.EVO_ITEM:
			result.trigger = EvolutionTrigger.Trigger.ITEM_USED
			var item: EvolutionConditionItem = EvolutionConditionItem.new()
			item.required_item_id = legacy.parameter
			result.conditions.append(item)
		PokemonData.EvolutionMethods.EVO_TRADE:
			result.trigger = EvolutionTrigger.Trigger.TRADE
		PokemonData.EvolutionMethods.EVO_BATTLE_END:
			result.trigger = EvolutionTrigger.Trigger.BATTLE_END
		PokemonData.EvolutionMethods.EVO_SPIN:
			result.trigger = EvolutionTrigger.Trigger.OVERWORLD_EVENT
		PokemonData.EvolutionMethods.EVO_SCRIPT_TRIGGER:
			result.trigger = EvolutionTrigger.Trigger.SCRIPT_EVENT
		_:
			result.trigger = EvolutionTrigger.Trigger.SCRIPT_EVENT

	if legacy.condition == PokemonData.EvolutionConditions.IF_MIN_FRIENDSHIP:
		var friendship: EvolutionConditionFriendship = EvolutionConditionFriendship.new()
		friendship.minimum_friendship = legacy.condition_value
		result.conditions.append(friendship)

	return result
