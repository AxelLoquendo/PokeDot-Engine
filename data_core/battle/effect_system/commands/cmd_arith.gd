## Operadores aritméticos sobre variables del contexto.
## Uso:
##   set x 10
##   add x 5
##   mul x 2
##   set query_int query_int * 2
##   set multiplier 1.5
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
	var current: float = _read(ctx, var_name)
	match command_name:
		"set":
			_write(ctx, var_name, value)
		"add":
			_write(ctx, var_name, current + value)
		"sub":
			_write(ctx, var_name, current - value)
		"mul":
			_write(ctx, var_name, current * value)
		"div":
			_write(ctx, var_name, current / value if value != 0.0 else 0.0)
		_:
			_write(ctx, var_name, value)
	return true


func _read(ctx: EffectContext, name: String) -> float:
	match name:
		"query_int":
			return float(ctx.query_int)
		"multiplier":
			return ctx.multiplier
		"damage":
			return float(ctx.damage)
		_:
			return float(ctx.vars.get(name, 0.0))


func _write(ctx: EffectContext, name: String, value: float) -> void:
	match name:
		"query_int":
			ctx.query_int = int(round(value))
		"multiplier":
			ctx.multiplier = value
		"damage":
			ctx.damage = int(round(value))
		_:
			ctx.vars[name] = value
