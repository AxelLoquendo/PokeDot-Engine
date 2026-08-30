extends RefCounted
class_name MoveEffectResolver

const _STAT_EFFECTS: Dictionary = {
	MoveStruct.MoveEffect.EFFECT_ATTACK_UP: [PokemonInstance.Stat.ATTACK, 1],
	MoveStruct.MoveEffect.EFFECT_ATTACK_UP_2: [PokemonInstance.Stat.ATTACK, 2],
	MoveStruct.MoveEffect.EFFECT_ATTACK_DOWN: [PokemonInstance.Stat.ATTACK, -1],
	MoveStruct.MoveEffect.EFFECT_ATTACK_DOWN_2: [PokemonInstance.Stat.ATTACK, -2],

	MoveStruct.MoveEffect.EFFECT_DEFENSE_UP: [PokemonInstance.Stat.DEFENSE, 1],
	MoveStruct.MoveEffect.EFFECT_DEFENSE_UP_2: [PokemonInstance.Stat.DEFENSE, 2],
	MoveStruct.MoveEffect.EFFECT_DEFENSE_UP_3: [PokemonInstance.Stat.DEFENSE, 3],
	MoveStruct.MoveEffect.EFFECT_DEFENSE_DOWN: [PokemonInstance.Stat.DEFENSE, -1],
	MoveStruct.MoveEffect.EFFECT_DEFENSE_DOWN_2: [PokemonInstance.Stat.DEFENSE, -2],

	MoveStruct.MoveEffect.EFFECT_SPEED_UP: [PokemonInstance.Stat.SPEED, 1],
	MoveStruct.MoveEffect.EFFECT_SPEED_UP_2: [PokemonInstance.Stat.SPEED, 2],
	MoveStruct.MoveEffect.EFFECT_SPEED_DOWN: [PokemonInstance.Stat.SPEED, -1],
	MoveStruct.MoveEffect.EFFECT_SPEED_DOWN_2: [PokemonInstance.Stat.SPEED, -2],

	MoveStruct.MoveEffect.EFFECT_SPECIAL_ATTACK_UP: [PokemonInstance.Stat.SP_ATTACK, 1],
	MoveStruct.MoveEffect.EFFECT_SPECIAL_ATTACK_UP_2: [PokemonInstance.Stat.SP_ATTACK, 2],
	MoveStruct.MoveEffect.EFFECT_SPECIAL_ATTACK_UP_3: [PokemonInstance.Stat.SP_ATTACK, 3],
	MoveStruct.MoveEffect.EFFECT_SPECIAL_ATTACK_DOWN: [PokemonInstance.Stat.SP_ATTACK, -1],
	MoveStruct.MoveEffect.EFFECT_SPECIAL_ATTACK_DOWN_2: [PokemonInstance.Stat.SP_ATTACK, -2],

	MoveStruct.MoveEffect.EFFECT_SPECIAL_DEFENSE_UP: [PokemonInstance.Stat.SP_DEFENSE, 1],
	MoveStruct.MoveEffect.EFFECT_SPECIAL_DEFENSE_UP_2: [PokemonInstance.Stat.SP_DEFENSE, 2],
	MoveStruct.MoveEffect.EFFECT_SPECIAL_DEFENSE_DOWN: [PokemonInstance.Stat.SP_DEFENSE, -1],
	MoveStruct.MoveEffect.EFFECT_SPECIAL_DEFENSE_DOWN_2: [PokemonInstance.Stat.SP_DEFENSE, -2],
}

const _ACCURACY_EVASION_EFFECTS: Dictionary = {
	MoveStruct.MoveEffect.EFFECT_ACCURACY_UP: ["acc", 1],
	MoveStruct.MoveEffect.EFFECT_ACCURACY_UP_2: ["acc", 2],
	MoveStruct.MoveEffect.EFFECT_ACCURACY_DOWN: ["acc", -1],
	MoveStruct.MoveEffect.EFFECT_ACCURACY_DOWN_2: ["acc", -2],
	MoveStruct.MoveEffect.EFFECT_EVASION_UP: ["eva", 1],
	MoveStruct.MoveEffect.EFFECT_EVASION_UP_2: ["eva", 2],
	MoveStruct.MoveEffect.EFFECT_EVASION_DOWN: ["eva", -1],
	MoveStruct.MoveEffect.EFFECT_EVASION_DOWN_2: ["eva", -2],
}

const _SECONDARY_STAT_EFFECTS: Dictionary = {
	MoveStruct.SecondaryEffect.MOVE_EFFECT_ATK_PLUS_1: [PokemonInstance.Stat.ATTACK, 1],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_ATK_PLUS_2: [PokemonInstance.Stat.ATTACK, 2],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_ATK_MINUS_1: [PokemonInstance.Stat.ATTACK, -1],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_ATK_MINUS_2: [PokemonInstance.Stat.ATTACK, -2],

	MoveStruct.SecondaryEffect.MOVE_EFFECT_DEF_PLUS_1: [PokemonInstance.Stat.DEFENSE, 1],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_DEF_PLUS_2: [PokemonInstance.Stat.DEFENSE, 2],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_DEF_MINUS_1: [PokemonInstance.Stat.DEFENSE, -1],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_DEF_MINUS_2: [PokemonInstance.Stat.DEFENSE, -2],

	MoveStruct.SecondaryEffect.MOVE_EFFECT_SPD_PLUS_1: [PokemonInstance.Stat.SPEED, 1],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_SPD_PLUS_2: [PokemonInstance.Stat.SPEED, 2],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_SPD_MINUS_1: [PokemonInstance.Stat.SPEED, -1],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_SPD_MINUS_2: [PokemonInstance.Stat.SPEED, -2],

	MoveStruct.SecondaryEffect.MOVE_EFFECT_SP_ATK_PLUS_1: [PokemonInstance.Stat.SP_ATTACK, 1],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_SP_ATK_PLUS_2: [PokemonInstance.Stat.SP_ATTACK, 2],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_SP_ATK_MINUS_1: [PokemonInstance.Stat.SP_ATTACK, -1],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_SP_ATK_MINUS_2: [PokemonInstance.Stat.SP_ATTACK, -2],

	MoveStruct.SecondaryEffect.MOVE_EFFECT_SP_DEF_PLUS_1: [PokemonInstance.Stat.SP_DEFENSE, 1],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_SP_DEF_PLUS_2: [PokemonInstance.Stat.SP_DEFENSE, 2],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_SP_DEF_MINUS_1: [PokemonInstance.Stat.SP_DEFENSE, -1],
	MoveStruct.SecondaryEffect.MOVE_EFFECT_SP_DEF_MINUS_2: [PokemonInstance.Stat.SP_DEFENSE, -2],
}

const _SECONDARY_STATUS_EFFECTS: Dictionary = {
	MoveStruct.SecondaryEffect.MOVE_EFFECT_SLEEP: PokemonInstance.Status.SLEEP,
	MoveStruct.SecondaryEffect.MOVE_EFFECT_POISON: PokemonInstance.Status.POISON,
	MoveStruct.SecondaryEffect.MOVE_EFFECT_BURN: PokemonInstance.Status.BURN,
	MoveStruct.SecondaryEffect.MOVE_EFFECT_FREEZE: PokemonInstance.Status.FREEZE,
	MoveStruct.SecondaryEffect.MOVE_EFFECT_PARALYSIS: PokemonInstance.Status.PARALYSIS,
	MoveStruct.SecondaryEffect.MOVE_EFFECT_TOXIC: PokemonInstance.Status.TOXIC,
}


static func get_primary_stat_effect(effect: MoveStruct.MoveEffect) -> Array:
	return _STAT_EFFECTS.get(effect, [])

static func get_primary_accuracy_evasion_effect(effect: MoveStruct.MoveEffect) -> Array:
	return _ACCURACY_EVASION_EFFECTS.get(effect, [])

static func get_secondary_stat_effect(effect: MoveStruct.SecondaryEffect) -> Array:
	return _SECONDARY_STAT_EFFECTS.get(effect, [])

static func get_secondary_status(effect: MoveStruct.SecondaryEffect) -> int:
	return _SECONDARY_STATUS_EFFECTS.get(effect, -1)

static func is_confuse_effect(effect: MoveStruct.MoveEffect, secondary: MoveStruct.SecondaryEffect) -> bool:
	return effect == MoveStruct.MoveEffect.EFFECT_CONFUSE \
		or secondary == MoveStruct.SecondaryEffect.MOVE_EFFECT_CONFUSION

static func is_flinch_effect(secondary: MoveStruct.SecondaryEffect) -> bool:
	return secondary == MoveStruct.SecondaryEffect.MOVE_EFFECT_FLINCH
