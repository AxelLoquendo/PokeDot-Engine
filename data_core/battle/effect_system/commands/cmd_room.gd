## Habitaciones de campo: trick_room, wonder_room, magic_room, gravity
class_name CmdRoom
extends EffectCommand


func _init(p_args: PackedStringArray = []) -> void:
	super._init("room", p_args)


func execute(ctx: EffectContext) -> bool:
	if ctx == null or ctx.battle == null:
		return false
	var kind: String = arg_string(0).to_lower()
	var turns: int = arg_int(1, 5)
	match kind:
		"trick_room", "trick":
			if ctx.battle.trick_room_turns > 0:
				ctx.battle.trick_room_turns = 0
				ctx.battle.message.emit("¡El Espacio Raro se disipó!")
			else:
				ctx.battle.trick_room_turns = turns
				ctx.battle.message.emit("¡Las dimensiones se distorsionaron!")
		"wonder_room", "wonder":
			if ctx.battle.wonder_room_turns > 0:
				ctx.battle.wonder_room_turns = 0
				ctx.battle.message.emit("¡Mundo Maravilla se disipó!")
			else:
				ctx.battle.wonder_room_turns = turns
				ctx.battle.message.emit("¡Defensa y Def. Especial se intercambiaron!")
		"magic_room", "magic":
			if ctx.battle.magic_room_turns > 0:
				ctx.battle.magic_room_turns = 0
				ctx.battle.message.emit("¡Zona Extraña se disipó!")
			else:
				ctx.battle.magic_room_turns = turns
				ctx.battle.message.emit("¡Los objetos perdieron su efecto!")
		"gravity":
			ctx.battle.gravity_turns = turns
			for b: BattleBattler in ctx.battle.get_all_actives():
				if b != null:
					b.set_meta("gravity_active", true)
			ctx.battle.message.emit("¡La gravedad se intensificó!")
		_:
			push_warning("CmdRoom: desconocido '%s'" % kind)
			return false
	return true
