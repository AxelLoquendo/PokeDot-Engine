class_name CmdAnnounce
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("announce", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true
	var mode: String = "user"
	for i: int in range(args.size()):
		var a: String = args[i].to_lower()
		if a.begins_with("target="):
			mode = a.substr(7)
	var who: BattleBattler = _resolve(ctx, mode)
	if who == null:
		return true
	await ctx.battle.ability_announce(who)
	return true


func _resolve(ctx: EffectContext, mode: String) -> BattleBattler:
	match mode:
		"current":
			if ctx.has_meta("foreach_current"):
				return ctx.get_meta("foreach_current") as BattleBattler
			return ctx.user
		"target":
			return ctx.target
		"attacker":
			return ctx.attacker
		"opponent":
			return ctx.target
		_:
			return ctx.user
