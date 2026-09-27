class_name CmdAnnounce
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("announce", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null or ctx.user == null:
		return true
	await ctx.battle.ability_announce(ctx.user)
	return true
