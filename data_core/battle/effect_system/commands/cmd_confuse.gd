class_name CmdConfuse
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("confuse", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx == null or ctx.battle == null:
		return false
	var who: BattleBattler = ctx.target
	for a: String in args:
		if a.begins_with("target="):
			match a.substr(7).to_lower():
				"user":
					who = ctx.user
				"opponent", "foe", "target":
					who = ctx.target
				"attacker":
					who = ctx.attacker if ctx.attacker else ctx.user
	if who == null:
		return false
	if ctx.battle.has_method("_apply_confusion"):
		await ctx.battle._apply_confusion(who)
	else:
		if AbilityRuntime.blocks_confusion(who):
			return true
		who.confusion_turns = randi_range(2, 5)
		ctx.battle.message.emit("¡%s se confundió!" % who.get_display_name())
	return true
