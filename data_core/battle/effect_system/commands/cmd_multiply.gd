## Multiplica el valor de consulta actual (ctx.multiplier).
## Uso:
##   multiply 1.5
##   multiply 2.0
##   multiply power 1.5
##   multiply speed 2.0
##   multiply damage_taken 0.5
##   multiply 3 / 4
##
## El canal (power, speed, …) es documentación ejecutable para el autor del .txt.
## Todos los canales de multiplicador de consulta escriben en ctx.multiplier,
## que es lo que AbilitySystem.query_float devuelve.
class_name CmdMultiply
extends EffectCommand

const CHANNELS: Array[String] = [
	"multiplier", "power", "speed", "damage_taken", "attack_stat",
	"stab", "crit", "weight", "aura", "ruin", "analytic", "stakeout",
	"sand_force", "solar_power", "engine_pulse", "grass_pelt", "marvel_scale",
	"rivalry", "friend_guard", "battery", "power_spot", "flower_gift_stat",
	"plus_minus", "supreme_overlord", "berry_threshold", "berry_effect", "type_power",
]


func _init(p_args: PackedStringArray = []) -> void:
	super._init("multiply", p_args)


func execute(ctx: EffectContext) -> bool:
	var channel: String = "multiplier"
	var expr: String = ""
	if args.is_empty():
		push_warning("CmdMultiply: falta el factor")
		return true
	var first: String = arg_string(0).to_lower()
	if first in CHANNELS or (args.size() >= 2 and not _starts_like_expr(first)):
		channel = first
		expr = " ".join(args.slice(1))
	else:
		expr = " ".join(args)
	if expr.is_empty():
		push_warning("CmdMultiply: falta el factor (canal=%s)" % channel)
		return true
	var factor: float = EffectExpr.eval(expr, ctx)
	ctx.multiplier *= factor
	return true


func _starts_like_expr(s: String) -> bool:
	if s.is_empty():
		return false
	var c: String = s[0]
	return c.is_valid_float() or c == "(" or c == "-" or c == "+"
