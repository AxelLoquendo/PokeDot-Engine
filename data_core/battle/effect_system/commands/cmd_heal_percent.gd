## heal_percent 12.5 target=user
class_name CmdHealPercent
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("heal_percent", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true
	var percent: float = arg_float(0, 12.5)
	var mode: String = "user"
	for i: int in range(1, args.size()):
		var a: String = args[i].to_lower()
		if a.begins_with("target="):
			mode = a.substr(7)
	var who: BattleBattler = ctx.user if mode == "user" else ctx.target
	if mode == "current" and ctx.has_meta("foreach_current"):
		who = ctx.get_meta("foreach_current") as BattleBattler
	if who == null or who.is_fainted():
		return true
	var amount: int = maxi(1, int(floor(float(who.get_max_hp()) * percent / 100.0)))
	await ctx.battle.ability_heal(who, amount)
	return true
