## Imposter: transforma en el oponente.
## Uso: setup_imposter
##      setup_imposter target=opponent
class_name CmdSetupImposter
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("setup_imposter", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null or ctx.user == null:
		return true
	var opp: BattleBattler = ctx.target
	if opp == null or opp.is_fainted():
		return true
	await AbilityRuntime._setup_imposter(ctx.user, opp, ctx.battle)
	return true
