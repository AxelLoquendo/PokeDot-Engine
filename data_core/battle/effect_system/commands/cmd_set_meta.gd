## set_meta slow_start_turns 5
## set_meta zero_to_hero_armed true
class_name CmdSetMeta
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("set_meta", p_args)


func execute(ctx: EffectContext) -> bool:
	var key: String = arg_string(0)
	var val_s: String = arg_string(1)
	if key.is_empty() or ctx.user == null:
		return true
	var val: Variant = val_s
	if val_s.is_valid_int():
		val = int(val_s)
	elif val_s.to_lower() == "true":
		val = true
	elif val_s.to_lower() == "false":
		val = false
	# Propiedades conocidas del battler
	match key:
		"slow_start_turns":
			ctx.user.slow_start_turns = int(val)
		"zero_to_hero_transformed":
			ctx.user.zero_to_hero_transformed = bool(val)
		_:
			ctx.user.set_meta(key, val)
			if ctx.user.pokemon != null:
				ctx.user.pokemon.set_meta(key, val)
	return true
