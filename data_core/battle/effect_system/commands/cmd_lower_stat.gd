## Cambia stages de una estadística (negativo = bajar).
## Uso:
##   lower_stat ATK 1 target=opponent caused_by_foe
##   raise_stat SPEED 1 target=user
##
## Stats: ATK DEF SPEED SPATK SPDEF
## target= user | target | opponent | attacker
class_name CmdLowerStat
extends EffectCommand

const STAT_MAP: Dictionary = {
	"atk": PokemonInstance.Stat.ATTACK,
	"attack": PokemonInstance.Stat.ATTACK,
	"def": PokemonInstance.Stat.DEFENSE,
	"defense": PokemonInstance.Stat.DEFENSE,
	"spatk": PokemonInstance.Stat.SP_ATTACK,
	"spa": PokemonInstance.Stat.SP_ATTACK,
	"sp_attack": PokemonInstance.Stat.SP_ATTACK,
	"spdef": PokemonInstance.Stat.SP_DEFENSE,
	"spd": PokemonInstance.Stat.SP_DEFENSE,
	"sp_defense": PokemonInstance.Stat.SP_DEFENSE,
	"speed": PokemonInstance.Stat.SPEED,
	"spe": PokemonInstance.Stat.SPEED,
}


func _init(p_args: PackedStringArray = [], p_name: String = "lower_stat") -> void:
	super._init(p_name, p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true

	var stat_key: String = arg_string(0).to_lower()
	if not STAT_MAP.has(stat_key):
		push_warning("CmdLowerStat: stat desconocida '%s'" % stat_key)
		return true

	var stages: int = arg_int(1, 1)
	if command_name == "lower_stat" and stages > 0:
		stages = -stages

	var caused_by_foe: bool = false
	var target_mode: String = "opponent"

	for i: int in range(2, args.size()):
		var a: String = args[i].to_lower()
		if a == "caused_by_foe" or a == "from_foe":
			caused_by_foe = true
		elif a.begins_with("target="):
			target_mode = a.substr(7)

	var who: BattleBattler = _resolve_target(ctx, target_mode)
	if who == null or who.is_fainted():
		return true

	var stat: PokemonInstance.Stat = STAT_MAP[stat_key] as PokemonInstance.Stat
	await ctx.battle.ability_change_stat(who, stat, stages, caused_by_foe)
	return true


func _resolve_target(ctx: EffectContext, mode: String) -> BattleBattler:
	match mode:
		"user":
			return ctx.user
		"attacker":
			return ctx.attacker if ctx.attacker != null else ctx.user
		"target":
			return ctx.target if ctx.target != null else ctx.user
		"opponent", "foe":
			if ctx.battle != null and ctx.user != null and ctx.battle.has_method("get_opponents"):
				var foes: Array = ctx.battle.get_opponents(ctx.user)
				for f: Variant in foes:
					var b: BattleBattler = f as BattleBattler
					if b != null and not b.is_fainted():
						return b
			return ctx.target
		_:
			return ctx.target if ctx.target != null else ctx.user
