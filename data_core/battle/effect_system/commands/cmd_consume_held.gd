## consume_held
## Consume el objeto equipado del usuario (bayas, Focus Sash, etc.).
class_name CmdConsumeHeld
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("consume_held", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.user == null:
		return true
	HoldItemRuntime.consume_held(ctx.user)
	return true
