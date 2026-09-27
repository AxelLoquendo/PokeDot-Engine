## Declara una inmunidad / reacción a un movimiento.
## Uso (uno o más matchers OR):
##   immunity immune GROUND unless=damages_airborne
##   immunity heal ELECTRIC
##   immunity heal WATER
##   immunity spatk_up WATER ELECTRIC
##   immunity immune SOUND BALLISTIC
##   immunity atk_up WIND
##   immunity flash_fire FIRE
##   immunity def_up FIRE
##
## Matchers: tipos (FIRE, WATER, ...) o flags (SOUND, BALLISTIC, WIND, CONTACT, PUNCH, ...)
class_name CmdImmunity
extends EffectCommand

const TYPE_KEYS: PackedStringArray = [
	"normal", "fighting", "flying", "poison", "ground", "rock", "bug", "ghost",
	"steel", "fire", "water", "grass", "electric", "psychic", "ice", "dragon",
	"dark", "fairy",
]


func _init(p_args: PackedStringArray = []) -> void:
	super._init("immunity", p_args)


func execute(ctx: EffectContext) -> bool:
	if args.is_empty():
		return true
	var reaction: String = arg_string(0).to_lower()
	if ctx.move == null:
		return true

	var unless_flag: String = ""
	var matchers: PackedStringArray = PackedStringArray()
	for i: int in range(1, args.size()):
		var a: String = args[i]
		if a.to_lower().begins_with("unless="):
			unless_flag = a.substr(7).to_lower()
			continue
		matchers.append(a)

	if not unless_flag.is_empty() and EffectConditions._move_flag_matches(ctx, unless_flag):
		return true

	if matchers.is_empty():
		ctx.immunity_reaction = reaction
		ctx.blocked = reaction == "immune"
		return true

	if _any_matcher(ctx, matchers):
		ctx.immunity_reaction = reaction
		ctx.blocked = reaction == "immune"
	return true


func _any_matcher(ctx: EffectContext, matchers: PackedStringArray) -> bool:
	for m: String in matchers:
		var key: String = m.to_lower()
		if key in TYPE_KEYS:
			if _type_is(ctx, key):
				return true
			continue
		if EffectConditions._move_flag_matches(ctx, key):
			return true
	return false


func _type_is(ctx: EffectContext, type_name: String) -> bool:
	if ctx.move == null:
		return false
	var want: String = "TYPE_" + type_name.to_upper()
	var keys: Array = PokemonData.Type.keys()
	for k: Variant in keys:
		if str(k) == want:
			return int(ctx.move.type) == int(PokemonData.Type[str(k)])
	return false
