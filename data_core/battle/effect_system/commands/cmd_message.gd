## Muestra un mensaje en batalla.
## Uso: message "¡{user} intimidó a {target}!"
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

	ctx.add_message(text)
	return true


func _name(b: BattleBattler) -> String:
	if b != null and b.pokemon != null:
		if b.pokemon.has_method("get_display_name"):
			return b.pokemon.get_display_name()
		return str(b.pokemon)
	return "???"
