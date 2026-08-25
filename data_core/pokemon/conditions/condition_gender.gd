@tool
extends EvolutionCondition

class_name EvolutionConditionGender

@export var required_gender: PokemonData.Gender = PokemonData.Gender.GENDERLESS

func is_met(context: EvolutionContext) -> bool:
	return context != null and context.pokemon != null and context.pokemon.gender == required_gender

func get_description() -> String:
	return "Género: %s" % PokemonData.Gender.keys()[int(required_gender)].capitalize()
