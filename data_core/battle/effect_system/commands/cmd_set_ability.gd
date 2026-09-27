## set_ability target=attacker from=user
## set_ability target=attacker ability=MUMMY
class_name CmdSetAbility
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("set_ability", p_args)


func execute(ctx: EffectContext) -> bool:
	var target_mode: String = "attacker"
	var from_mode: String = "user"
	var ability_name: String = ""
	for i: int in range(args.size()):
		var a: String = args[i]
		var low: String = a.to_lower()
		if low.begins_with("target="):
			target_mode = low.substr(7)
		elif low.begins_with("from="):
			from_mode = low.substr(5)
		elif low.begins_with("ability="):
			ability_name = a.substr(8).to_upper()

	var who: BattleBattler = _resolve(ctx, target_mode)
	if who == null or who.pokemon == null:
		return true

	var new_id: AbilityId.Id = AbilityId.Id.NONE
	if not ability_name.is_empty():
		new_id = _parse_ability(ability_name)
	else:
		var src: BattleBattler = _resolve(ctx, from_mode)
		if src != null and src.pokemon != null:
			new_id = src.pokemon.ability_id

	if new_id == AbilityId.Id.NONE:
		return true
	who.pokemon.ability_id = new_id
	if ctx.battle != null:
		ctx.battle.message.emit("¡La habilidad de %s cambió!" % who.get_display_name())
		await ctx.battle._wait(0.6)
	return true


func _resolve(ctx: EffectContext, mode: String) -> BattleBattler:
	match mode:
		"attacker":
			return ctx.attacker if ctx.attacker != null else ctx.target
		"target":
			return ctx.target
		"opponent":
			return ctx.target
		"current":
			if ctx.has_meta("foreach_current"):
				return ctx.get_meta("foreach_current") as BattleBattler
			return ctx.user
		_:
			return ctx.user


func _parse_ability(name: String) -> AbilityId.Id:
	var keys: Array = AbilityId.Id.keys()
	for i: int in range(keys.size()):
		if str(keys[i]) == name:
			return i as AbilityId.Id
	return AbilityId.Id.NONE
