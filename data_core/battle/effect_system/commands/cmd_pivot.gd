## Cambia al usuario (U-turn / Parting Shot / Baton Pass / Teleport).
##   pivot
##   pivot baton_pass
class_name CmdPivot
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("pivot", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx == null or ctx.battle == null or ctx.user == null:
		return false
	var baton: bool = false
	for a: String in args:
		if a.to_lower() in ["baton_pass", "baton", "true"]:
			baton = true
	if ctx.battle.has_method("_request_pivot_out"):
		await ctx.battle._request_pivot_out(ctx.user, baton)
	return true
