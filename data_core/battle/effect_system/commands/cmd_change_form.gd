## Cambia la forma del Pokémon (form_id del .tres de especie).
## Uso:
##   change_form Hero
##   change_form darmanitan_zen
##   change_form base
##   change_form castform_rainy target=user
class_name CmdChangeForm
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("change_form", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.battle == null:
		return true
	var form_str: String = arg_string(0)
	if form_str.is_empty():
		push_warning("CmdChangeForm: falta form_id")
		return true
	var mode: String = "user"
	for i: int in range(1, args.size()):
		var a: String = args[i].to_lower()
		if a.begins_with("target="):
			mode = a.substr(7)
	var who: BattleBattler = _resolve(ctx, mode)
	if who == null or who.pokemon == null:
		return true

	var form_id: StringName = StringName(form_str)
	# Reutiliza la lógica central del runtime
	await AbilityRuntime._apply_form_change(who, ctx.battle, form_id, false)
	return true


func _resolve(ctx: EffectContext, mode: String) -> BattleBattler:
	match mode:
		"target":
			return ctx.target
		"current":
			if ctx.has_meta("foreach_current"):
				return ctx.get_meta("foreach_current") as BattleBattler
			return ctx.user
		_:
			return ctx.user
