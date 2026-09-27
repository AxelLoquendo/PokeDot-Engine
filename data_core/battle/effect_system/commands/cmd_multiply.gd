## Multiplica el valor de consulta actual (ctx.multiplier).
## Uso:
##   multiply 1.5
##   multiply 2.0
##   multiply 3 / 4
##   multiply 1 + 1 / 2
class_name CmdMultiply
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("multiply", p_args)


func execute(ctx: EffectContext) -> bool:
	var expr: String = " ".join(args)
	if expr.is_empty():
		push_warning("CmdMultiply: falta el factor")
		return true
	var factor: float = EffectExpr.eval(expr, ctx)
	ctx.multiplier *= factor
	return true
