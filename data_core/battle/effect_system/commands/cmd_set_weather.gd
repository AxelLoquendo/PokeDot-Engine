## set_weather RAIN
## set_weather SUN -1
## set_weather RAIN -1 primal
class_name CmdSetWeather
extends EffectCommand

const WEATHER_MAP: Dictionary = {
	"none": 0,
	"rain": 1,
	"sun": 2,
	"drought": 2,
	"sand": 3,
	"sandstorm": 3,
	"snow": 4,
	"hail": 4,
}


func _init(p_args: PackedStringArray = []) -> void:
	super._init("set_weather", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true
	var key: String = arg_string(0).to_lower()
	var turns: int = arg_int(1, -1)
	var primal: bool = false
	for i: int in range(args.size()):
		if args[i].to_lower() == "primal":
			primal = true
	# Prefer AbilityBattleEffect enum values via battle if available
	var weather_id: int = int(WEATHER_MAP.get(key, 0))
	# Map to project constants when possible
	match key:
		"rain":
			weather_id = AbilityBattleEffect.weatherAbilityID.WEATHER_RAIN
		"sun", "drought":
			weather_id = AbilityBattleEffect.weatherAbilityID.WEATHER_DROUGHT
		"sand", "sandstorm":
			weather_id = AbilityBattleEffect.weatherAbilityID.WEATHER_SANDSTORM
		"snow", "hail":
			weather_id = AbilityBattleEffect.weatherAbilityID.WEATHER_SNOW
		"none":
			weather_id = AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
	if primal:
		ctx.battle.set_weather(weather_id, turns, true)
	else:
		ctx.battle.set_weather(weather_id, turns)
	return true
