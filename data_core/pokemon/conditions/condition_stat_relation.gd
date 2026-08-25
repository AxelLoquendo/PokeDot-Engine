@tool
extends EvolutionCondition

class_name EvolutionConditionStatRelation

enum Relation { GREATER, EQUAL, LESS }

@export var left_stat: PokemonInstance.Stat = PokemonInstance.Stat.ATTACK
@export var right_stat: PokemonInstance.Stat = PokemonInstance.Stat.DEFENSE
@export var relation: Relation = Relation.GREATER

func is_met(context: EvolutionContext) -> bool:
	if context == null or context.pokemon == null:
		return false
	var left: int = context.pokemon.get_stat(left_stat)
	var right: int = context.pokemon.get_stat(right_stat)
	match relation:
		Relation.GREATER:
			return left > right
		Relation.EQUAL:
			return left == right
		Relation.LESS:
			return left < right
	return false

func get_description() -> String:
	var symbol: String = ">"
	if relation == Relation.EQUAL:
		symbol = "="
	elif relation == Relation.LESS:
		symbol = "<"
	return "%s %s %s" % [PokemonInstance.Stat.keys()[int(left_stat)], symbol, PokemonInstance.Stat.keys()[int(right_stat)]]
