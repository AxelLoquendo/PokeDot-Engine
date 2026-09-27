## Operadores aritméticos sobre variables del contexto.
## Uso:
##   set x 10
##   add x 5
##   sub x 2
##   mul x 1.5
##   div x 2
##   set dmg damage * 0.125
class_name CmdArith
extends EffectCommand


func _init(p_args: PackedStringArray = [], p_name: String = "set") -> void:
	super._init(p_name, p_args)


func execute(ctx: EffectContext) -> bool:
	if args.is_empty():
		return true
	var var_name: String = arg_string(0).to_lower()
	var expr: String = ""
	for i: int in range(1, args.size()):
		if i > 1:
			expr += " "
		expr += args[i]
	if expr.is_empty():
		expr = "0"
	var value: float = EffectExpr.eval(expr, ctx)
	var current: float = float(ctx.vars.get(var_name, 0.0))
	match command_name:
		"set":
			ctx.vars[var_name] = value
		"add":
			ctx.vars[var_name] = current + value
		"sub":
			ctx.vars[var_name] = current - value
		"mul":
			ctx.vars[var_name] = current * value
		"div":
			ctx.vars[var_name] = current / value if value != 0.0 else 0.0
		_:
			ctx.vars[var_name] = value
	return true
