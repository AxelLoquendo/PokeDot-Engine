extends RefCounted
class_name TwoTurnResolver

const _CHARGE_MESSAGES: Dictionary = {
	Moves.MoveId.MOVE_FLY: "voló muy alto",
	Moves.MoveId.MOVE_DIG: "se escondió bajo tierra",
	Moves.MoveId.MOVE_DIVE: "se escondió bajo el agua",
	Moves.MoveId.MOVE_BOUNCE: "saltó muy alto",
	Moves.MoveId.MOVE_PHANTOM_FORCE: "desapareció",
	Moves.MoveId.MOVE_SHADOW_FORCE: "desapareció",
	Moves.MoveId.MOVE_SOLAR_BEAM: "absorbió luz",
	Moves.MoveId.MOVE_SKULL_BASH: "bajó la cabeza",
	Moves.MoveId.MOVE_RAZOR_WIND: "reunió el viento",
	Moves.MoveId.MOVE_SKY_ATTACK: "tomó impulso",
	Moves.MoveId.MOVE_METEOR_BEAM: "reunió energía estelar",
	Moves.MoveId.MOVE_FREEZE_SHOCK: "reunió electricidad",
	Moves.MoveId.MOVE_ICE_BURN: "se envolvió en fuego",
	Moves.MoveId.MOVE_GEOMANCY: "absorbió energía",
	Moves.MoveId.MOVE_SKY_DROP: "se llevó por los aires a su objetivo",
}


static func is_charge_move(move: MoveData) -> bool:
	return move != null and (
		move.effect == MoveStruct.MoveEffect.EFFECT_SEMI_INVULNERABLE
		or move.effect == MoveStruct.MoveEffect.EFFECT_SOLAR_BEAM
		or move.effect == MoveStruct.MoveEffect.EFFECT_TWO_TURNS_ATTACK
		or move.effect == MoveStruct.MoveEffect.EFFECT_GEOMANCY
		or move.effect == MoveStruct.MoveEffect.EFFECT_SKY_DROP
	)


static func is_recharge_move(move: MoveData) -> bool:
	return move != null and move.effect == MoveStruct.MoveEffect.EFFECT_RECHARGE


static func grants_invulnerability(move: MoveData) -> bool:
	return move != null and (
		move.effect == MoveStruct.MoveEffect.EFFECT_SEMI_INVULNERABLE
		or move.effect == MoveStruct.MoveEffect.EFFECT_SKY_DROP
	)


## Rayo Solar golpea sin cargar bajo sol intenso.
static func skips_charge_in_weather(move: MoveData, weather: int) -> bool:
	return move != null and move.effect == MoveStruct.MoveEffect.EFFECT_SOLAR_BEAM \
		and weather == AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT


static func charge_message(move: MoveData, user_name: String) -> String:
	var verb: String = _CHARGE_MESSAGES.get(move.move_id, "se está preparando")
	return "¡%s %s!" % [user_name, verb]
