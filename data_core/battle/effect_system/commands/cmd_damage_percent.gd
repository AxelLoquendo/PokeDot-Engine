## damage_percent 12.5 target=attacker
## Porcentaje del max HP del objetivo (12.5 = 1/8).
class_name CmdDamagePercent
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("damage_percent", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true
	var percent: float = arg_float(0, 12.5)
	var mode: String = "attacker"
	for i: int in range(1, args.size()):
		var a: String = args[i].to_lower()
		if a.begins_with("target="):
			mode = a.substr(7)
	var who: BattleBattler = _resolve(ctx, mode)
	var source: BattleBattler = ctx.user
	if who == null or who.is_fainted() or source == null:
		return true
	var dmg: int = maxi(1, int(floor(float(who.get_max_hp()) * percent / 100.0)))
	await ctx.battle.ability_deal_damage(who, dmg, source)
	return true


func _resolve(ctx: EffectContext, mode: String) -> BattleBattler:
	match mode:
		"user":
			return ctx.user
		"target":
			return ctx.target
		"attacker":
			return ctx.attacker if ctx.attacker != null else ctx.target
		"current":
			if ctx.has_meta("foreach_current"):
				return ctx.get_meta("foreach_current") as BattleBattler
			return ctx.target
		_:
			return ctx.attacker if ctx.attacker != null else ctx.target
