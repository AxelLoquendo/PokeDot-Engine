class_name CmdClearScreens
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("clear_screens", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true
	if ctx.battle.player_side != null:
		ctx.battle.player_side.clear_screens()
	if ctx.battle.enemy_side != null:
		ctx.battle.enemy_side.clear_screens()
	return true
