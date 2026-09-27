## infatuate target=attacker
class_name CmdInfatuate
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("infatuate", p_args)


func execute(ctx: EffectContext) -> bool:
	var who: BattleBattler = ctx.attacker if ctx.attacker != null else ctx.target
	var source: BattleBattler = ctx.user
	if who == null or source == null:
		return true
	if who.has_method("is_infatuated") and who.is_infatuated():
		return true
	# Misma lógica simplificada que Cute Charm (género se valida fuera o aquí)
	who.infatuated_by_player_side = 1 if source.is_player_side else 0
	if ctx.battle != null:
		ctx.battle.message.emit("¡%s se enamoró!" % who.get_display_name())
		await ctx.battle._wait(0.5)
	return true
