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
	var new_type_name: String = ""
	for i: int in range(args.size()):
		var a: String = args[i]
		var al: String = a.to_lower()
		if al.begins_with("if_type="):
			if_type = al.substr(8)
		elif new_type_name.is_empty():
			new_type_name = a
	if new_type_name.is_empty():
		return true
	if not if_type.is_empty():
		var cur: String = str(ctx.move.type).to_lower()
		if not cur.ends_with(if_type.to_lower()) and if_type.to_upper() not in str(ctx.move.type):
			# Compare via enum name
			var want: String = "TYPE_" + if_type.to_upper()
			if not (PokemonData.Type.has(want) and int(PokemonData.Type[want]) == int(ctx.move.type)):
				return true
	var key: String = "TYPE_" + new_type_name.to_upper()
	if PokemonData.Type.has(key):
		ctx.query_int = int(PokemonData.Type[key])
		# on_move_type readers use query_int
	return true
