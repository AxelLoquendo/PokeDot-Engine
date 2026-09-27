## Probabilidad. Los comandos siguientes hasta endchance solo se ejecutan si sale el %.
## Uso:
##   chance 30
##     status BURN
##   endchance
class_name CmdChance
extends EffectCommand

var percent: int = 100
var is_end: bool = false


func _init(p_args: PackedStringArray = [], p_is_end: bool = false) -> void:
	super._init("chance" if not p_is_end else "endchance", p_args)
	is_end = p_is_end
	if not is_end:
		percent = arg_int(0, 100)


func execute(ctx: EffectContext) -> bool:
	if is_end:
		return true

	var roll: int = randi() % 100
	var success: bool = roll < percent
	ctx.set_meta("last_chance_success", success)
	return true
