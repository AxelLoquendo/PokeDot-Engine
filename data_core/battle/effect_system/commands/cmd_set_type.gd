## Cambia el tipo efectivo del movimiento (Pixilate, Galvanize, Normalize…).
## Uso:
##   set_move_type FAIRY
##   set_move_type ELECTRIC if_type=NORMAL
class_name CmdSetMoveType
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("set_move_type", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.move == null or args.is_empty():
		return true
	var if_type: String = ""
	for i: int in range(args.size()):
		if args[i].to_lower().begins_with("if_type="):
			if_type = args[i].substr(8).to_lower()
	if not if_type.is_empty():
		var want: String = "TYPE_" + if_type.to_upper()
		var cur_name: String = str(PokemonData.Type.keys()[int(ctx.move.type)]) if int(ctx.move.type) < PokemonData.Type.keys().size() else ""
		if cur_name.to_upper() != want and not _type_equals(ctx.move.type, if_type):
			return true
	var new_name: String = arg_string(0)
	var keys: Array = PokemonData.Type.keys()
	var want_key: String = new_name.to_upper()
	if not want_key.begins_with("TYPE_"):
		want_key = "TYPE_" + want_key
	for k: Variant in keys:
		if str(k) == want_key:
			ctx.query_int = int(PokemonData.Type[str(k)])
			return true
	return true


func _type_equals(t: PokemonData.Type, name: String) -> bool:
	var want: String = "TYPE_" + name.to_upper()
	var keys: Array = PokemonData.Type.keys()
	for k: Variant in keys:
		if str(k) == want:
			return int(t) == int(PokemonData.Type[str(k)])
	return false
