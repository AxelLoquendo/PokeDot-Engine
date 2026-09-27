## Cambia el tipo de combate del portador (Protean, Color Change, Libero…).
## Uso:
##   set_type FIRE
##   set_type from=move
class_name CmdSetType
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("set_type", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx.user == null:
		return true
	var type_id: int = -1
	if args.is_empty():
		return true
	var a0: String = arg_string(0).to_lower()
	if a0 == "from=move" or a0 == "from_move":
		if ctx.move == null:
			return true
		type_id = int(ctx.move.type)
	else:
		type_id = _parse_type(a0)
	if type_id < 0:
		return true
	if ctx.user.has_method("set_battle_types"):
		ctx.user.set_battle_types(type_id as PokemonData.Type)
	return true


func _parse_type(name: String) -> int:
	var key: String = "TYPE_" + name.to_upper()
	if PokemonData.Type.has(key):
		return int(PokemonData.Type[key])
	return -1
