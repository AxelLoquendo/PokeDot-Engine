## swap_ability with=attacker
class_name CmdSwapAbility
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("swap_ability", p_args)


func execute(ctx: EffectContext) -> bool:
	var other: BattleBattler = ctx.attacker if ctx.attacker != null else ctx.target
	var me: BattleBattler = ctx.user
	if me == null or other == null or me.pokemon == null or other.pokemon == null:
		return true
	var a: AbilityId.Id = me.pokemon.ability_id
	var b: AbilityId.Id = other.pokemon.ability_id
	me.pokemon.ability_id = b
	other.pokemon.ability_id = a
	if ctx.battle != null:
		ctx.battle.message.emit("¡%s intercambió su habilidad!" % me.get_display_name())
		await ctx.battle._wait(0.6)
	return true
