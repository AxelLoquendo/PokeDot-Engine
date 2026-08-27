extends RefCounted
class_name TypeChart

const CHART: Dictionary = {
	PokemonData.Type.TYPE_NORMAL: {
		PokemonData.Type.TYPE_ROCK: 0.5,
		PokemonData.Type.TYPE_GHOST: 0.0,
		PokemonData.Type.TYPE_STEEL: 0.5,
	},
	PokemonData.Type.TYPE_FIGHTING: {
		PokemonData.Type.TYPE_NORMAL: 2.0,
		PokemonData.Type.TYPE_FLYING: 0.5,
		PokemonData.Type.TYPE_POISON: 0.5,
		PokemonData.Type.TYPE_ROCK: 2.0,
		PokemonData.Type.TYPE_BUG: 0.5,
		PokemonData.Type.TYPE_GHOST: 0.0,
		PokemonData.Type.TYPE_STEEL: 2.0,
		PokemonData.Type.TYPE_PSYCHIC: 0.5,
		PokemonData.Type.TYPE_ICE: 2.0,
		PokemonData.Type.TYPE_DARK: 2.0,
		PokemonData.Type.TYPE_FAIRY: 0.5,
	},
	PokemonData.Type.TYPE_FLYING: {
		PokemonData.Type.TYPE_FIGHTING: 2.0,
		PokemonData.Type.TYPE_ROCK: 0.5,
		PokemonData.Type.TYPE_BUG: 2.0,
		PokemonData.Type.TYPE_STEEL: 0.5,
		PokemonData.Type.TYPE_GRASS: 2.0,
		PokemonData.Type.TYPE_ELECTRIC: 0.5,
	},
	PokemonData.Type.TYPE_POISON: {
		PokemonData.Type.TYPE_POISON: 0.5,
		PokemonData.Type.TYPE_GROUND: 0.5,
		PokemonData.Type.TYPE_ROCK: 0.5,
		PokemonData.Type.TYPE_GHOST: 0.5,
		PokemonData.Type.TYPE_STEEL: 0.0,
		PokemonData.Type.TYPE_GRASS: 2.0,
		PokemonData.Type.TYPE_FAIRY: 2.0,
	},
	PokemonData.Type.TYPE_GROUND: {
		PokemonData.Type.TYPE_FLYING: 0.0,
		PokemonData.Type.TYPE_POISON: 2.0,
		PokemonData.Type.TYPE_ROCK: 2.0,
		PokemonData.Type.TYPE_BUG: 0.5,
		PokemonData.Type.TYPE_STEEL: 2.0,
		PokemonData.Type.TYPE_FIRE: 2.0,
		PokemonData.Type.TYPE_GRASS: 0.5,
		PokemonData.Type.TYPE_ELECTRIC: 2.0,
	},
	PokemonData.Type.TYPE_ROCK: {
		PokemonData.Type.TYPE_FIGHTING: 0.5,
		PokemonData.Type.TYPE_FLYING: 2.0,
		PokemonData.Type.TYPE_GROUND: 0.5,
		PokemonData.Type.TYPE_BUG: 2.0,
		PokemonData.Type.TYPE_STEEL: 0.5,
		PokemonData.Type.TYPE_FIRE: 2.0,
		PokemonData.Type.TYPE_ICE: 2.0,
	},
	PokemonData.Type.TYPE_BUG: {
		PokemonData.Type.TYPE_FIGHTING: 0.5,
		PokemonData.Type.TYPE_FLYING: 0.5,
		PokemonData.Type.TYPE_POISON: 0.5,
		PokemonData.Type.TYPE_GHOST: 0.5,
		PokemonData.Type.TYPE_STEEL: 0.5,
		PokemonData.Type.TYPE_FIRE: 0.5,
		PokemonData.Type.TYPE_GRASS: 2.0,
		PokemonData.Type.TYPE_PSYCHIC: 2.0,
		PokemonData.Type.TYPE_DARK: 2.0,
		PokemonData.Type.TYPE_FAIRY: 0.5,
	},
	PokemonData.Type.TYPE_GHOST: {
		PokemonData.Type.TYPE_NORMAL: 0.0,
		PokemonData.Type.TYPE_GHOST: 2.0,
		PokemonData.Type.TYPE_PSYCHIC: 2.0,
		PokemonData.Type.TYPE_DARK: 0.5,
	},
	PokemonData.Type.TYPE_STEEL: {
		PokemonData.Type.TYPE_ROCK: 2.0,
		PokemonData.Type.TYPE_STEEL: 0.5,
		PokemonData.Type.TYPE_FIRE: 0.5,
		PokemonData.Type.TYPE_WATER: 0.5,
		PokemonData.Type.TYPE_ELECTRIC: 0.5,
		PokemonData.Type.TYPE_ICE: 2.0,
		PokemonData.Type.TYPE_FAIRY: 2.0,
	},
	PokemonData.Type.TYPE_FIRE: {
		PokemonData.Type.TYPE_ROCK: 0.5,
		PokemonData.Type.TYPE_BUG: 2.0,
		PokemonData.Type.TYPE_STEEL: 2.0,
		PokemonData.Type.TYPE_FIRE: 0.5,
		PokemonData.Type.TYPE_WATER: 0.5,
		PokemonData.Type.TYPE_GRASS: 2.0,
		PokemonData.Type.TYPE_ICE: 2.0,
		PokemonData.Type.TYPE_DRAGON: 0.5,
	},
	PokemonData.Type.TYPE_WATER: {
		PokemonData.Type.TYPE_GROUND: 2.0,
		PokemonData.Type.TYPE_ROCK: 2.0,
		PokemonData.Type.TYPE_FIRE: 2.0,
		PokemonData.Type.TYPE_WATER: 0.5,
		PokemonData.Type.TYPE_GRASS: 0.5,
		PokemonData.Type.TYPE_DRAGON: 0.5,
	},
	PokemonData.Type.TYPE_GRASS: {
		PokemonData.Type.TYPE_FLYING: 0.5,
		PokemonData.Type.TYPE_POISON: 0.5,
		PokemonData.Type.TYPE_GROUND: 2.0,
		PokemonData.Type.TYPE_ROCK: 2.0,
		PokemonData.Type.TYPE_BUG: 0.5,
		PokemonData.Type.TYPE_STEEL: 0.5,
		PokemonData.Type.TYPE_FIRE: 0.5,
		PokemonData.Type.TYPE_WATER: 2.0,
		PokemonData.Type.TYPE_GRASS: 0.5,
		PokemonData.Type.TYPE_DRAGON: 0.5,
	},
	PokemonData.Type.TYPE_ELECTRIC: {
		PokemonData.Type.TYPE_FLYING: 2.0,
		PokemonData.Type.TYPE_GROUND: 0.0,
		PokemonData.Type.TYPE_WATER: 2.0,
		PokemonData.Type.TYPE_GRASS: 0.5,
		PokemonData.Type.TYPE_ELECTRIC: 0.5,
		PokemonData.Type.TYPE_DRAGON: 0.5,
	},
	PokemonData.Type.TYPE_PSYCHIC: {
		PokemonData.Type.TYPE_FIGHTING: 2.0,
		PokemonData.Type.TYPE_POISON: 2.0,
		PokemonData.Type.TYPE_STEEL: 0.5,
		PokemonData.Type.TYPE_PSYCHIC: 0.5,
		PokemonData.Type.TYPE_DARK: 0.0,
	},
	PokemonData.Type.TYPE_ICE: {
		PokemonData.Type.TYPE_FLYING: 2.0,
		PokemonData.Type.TYPE_GROUND: 2.0,
		PokemonData.Type.TYPE_STEEL: 0.5,
		PokemonData.Type.TYPE_FIRE: 0.5,
		PokemonData.Type.TYPE_WATER: 0.5,
		PokemonData.Type.TYPE_GRASS: 2.0,
		PokemonData.Type.TYPE_ICE: 0.5,
		PokemonData.Type.TYPE_DRAGON: 2.0,
	},
	PokemonData.Type.TYPE_DRAGON: {
		PokemonData.Type.TYPE_STEEL: 0.5,
		PokemonData.Type.TYPE_DRAGON: 2.0,
		PokemonData.Type.TYPE_FAIRY: 0.0,
	},
	PokemonData.Type.TYPE_DARK: {
		PokemonData.Type.TYPE_FIGHTING: 0.5,
		PokemonData.Type.TYPE_GHOST: 2.0,
		PokemonData.Type.TYPE_PSYCHIC: 2.0,
		PokemonData.Type.TYPE_DARK: 0.5,
		PokemonData.Type.TYPE_FAIRY: 0.5,
	},
	PokemonData.Type.TYPE_FAIRY: {
		PokemonData.Type.TYPE_FIGHTING: 2.0,
		PokemonData.Type.TYPE_POISON: 0.5,
		PokemonData.Type.TYPE_STEEL: 0.5,
		PokemonData.Type.TYPE_FIRE: 0.5,
		PokemonData.Type.TYPE_DRAGON: 2.0,
		PokemonData.Type.TYPE_DARK: 2.0,
	},
}


static func get_multiplier(attack_type: PokemonData.Type, defend_type: PokemonData.Type) -> float:
	if attack_type == PokemonData.Type.TYPE_NONE or defend_type == PokemonData.Type.TYPE_NONE:
		return 1.0
	if not CHART.has(attack_type):
		return 1.0
	var row: Dictionary = CHART[attack_type]
	if row.has(defend_type):
		return float(row[defend_type])
	return 1.0


static func get_effectiveness(
	move_type: PokemonData.Type,
	def_type1: PokemonData.Type,
	def_type2: PokemonData.Type = PokemonData.Type.TYPE_NONE
) -> float:
	var mult: float = get_multiplier(move_type, def_type1)
	if def_type2 != PokemonData.Type.TYPE_NONE and def_type2 != def_type1:
		mult *= get_multiplier(move_type, def_type2)
	return mult
