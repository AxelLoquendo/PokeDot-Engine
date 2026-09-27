## Roar / Whirlwind: obliga al rival a cambiar.
class_name CmdForceSwitch
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("force_switch", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx == null or ctx.battle == null:
		return false
	var who: BattleBattler = ctx.target
	if who == null and ctx.user != null and ctx.battle.has_method("get_opponents"):
		var opps: Array = ctx.battle.get_opponents(ctx.user)
		if not opps.is_empty():
			who = opps[0]
	if who == null:
		return false
	if ctx.battle.has_method("_force_switch_out"):
		await ctx.battle._force_switch_out(who)
	return true
