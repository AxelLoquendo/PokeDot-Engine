class_name CmdInfatuate
extends EffectCommand

func _init(p_args: PackedStringArray = []) -> void:
	super._init("infatuate", p_args)

func execute(ctx: EffectContext) -> bool:
	var mode: String = "attacker"
	for i: int in range(args.size()):
		var a: String = args[i].to_lower()
		if a.begins_with("target="):
			mode = a.substr(7)
	var who: BattleBattler = _resolve(ctx, mode)
	var source: BattleBattler = ctx.user
	if who == null or source == null:
		return true
	if who.has_method("is_infatuated") and who.is_infatuated():
		return true
	who.infatuated_by_player_side = 1 if source.is_player_side else 0
	if ctx.battle != null:
		ctx.battle.message.emit("¡%s se enamoró!" % who.get_display_name())
		await ctx.battle._wait(0.5)
	return true

func _resolve(ctx: EffectContext, mode: String) -> BattleBattler:
	match mode:
		"user":
			return ctx.user
		"target", "opponent", "foe":
			return ctx.target
		_:
			return ctx.attacker if ctx.attacker != null else ctx.target
