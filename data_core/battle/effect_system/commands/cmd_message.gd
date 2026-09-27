## message "¡{user} ... {current}!"
class_name CmdMessage
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("message", p_args)


func execute(ctx: EffectContext) -> bool:
	var text: String = arg_string(0)
	if text.is_empty():
		return true

	text = text.replace("{user}", _name(ctx.user))
	text = text.replace("{target}", _name(ctx.target))
	text = text.replace("{attacker}", _name(ctx.attacker))
	if ctx.has_meta("foreach_current"):
		text = text.replace("{current}", _name(ctx.get_meta("foreach_current") as BattleBattler))
	else:
		text = text.replace("{current}", _name(ctx.target))

	ctx.add_message(text)
	if ctx.battle != null:
		ctx.battle.message.emit(text)
		if ctx.battle.has_method("_wait"):
			await ctx.battle._wait(0.5)
	return true


func _name(b: BattleBattler) -> String:
	if b != null:
		if b.has_method("get_display_name"):
			return b.get_display_name()
		if b.pokemon != null:
			return str(b.pokemon)
	return "???"
