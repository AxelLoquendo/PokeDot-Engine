class_name CmdCureStatus
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("cure_status", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true
	var mode: String = "user"
	for i: int in range(args.size()):
		if args[i].to_lower().begins_with("target="):
			mode = args[i].substr(7).to_lower()
	var who: BattleBattler = ctx.user
	if mode == "target":
		who = ctx.target
	elif mode == "ally" and ctx.battle.has_method("get_ally"):
		who = ctx.battle.get_ally(ctx.user)
	if who == null:
		return true
	await ctx.battle.ability_cure_status(who)
	return true
