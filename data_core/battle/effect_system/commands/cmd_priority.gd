## Ajusta la prioridad del movimiento.
## Uso: priority 1    priority 3    priority -7
class_name CmdPriority
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("priority", p_args)


func execute(ctx: EffectContext) -> bool:
	ctx.query_int += arg_int(0, 0)
	return true
