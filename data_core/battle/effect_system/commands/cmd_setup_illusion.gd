## Activa Illusion (apariencia del último del party).
## Uso: setup_illusion
class_name CmdSetupIllusion
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("setup_illusion", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null or ctx.user == null:
		return true
	if ctx.user.illusion_active:
		return true
	var ok: bool = AbilityRuntime.prepare_illusion(ctx.user, ctx.battle)
	if ok:
		ctx.battle.battler_appearance_changed.emit(ctx.user.is_player_side)
	return true
