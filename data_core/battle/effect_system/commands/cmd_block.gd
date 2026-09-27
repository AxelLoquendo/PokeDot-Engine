## Marca una consulta booleana como verdadera.
## Uso:
##   block
##   block_status SLEEP
##   block_status POISON TOXIC
##   block_status ALL
class_name CmdBlock
extends EffectCommand


func _init(p_args: PackedStringArray = [], p_name: String = "block") -> void:
	super._init(p_name, p_args)


func execute(ctx: EffectContext) -> bool:
	if command_name == "block_status":
		if args.is_empty() or arg_string(0).to_lower() == "all":
			ctx.query_bool = true
			ctx.blocked = true
			return true
		# Si el contexto trae el estado consultado, coincidir
		if ctx.query_status >= 0:
			if EffectConditions._status_matches(ctx.query_status, args, 0):
				ctx.query_bool = true
				ctx.blocked = true
			return true
		ctx.query_bool = true
		ctx.blocked = true
		return true

	ctx.query_bool = true
	ctx.blocked = true
	return true
