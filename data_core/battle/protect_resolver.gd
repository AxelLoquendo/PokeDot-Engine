extends RefCounted
class_name ProtectResolver

enum Kind {
	NONE,
	BASIC,          # Protect, Detect, Mat Block
	SPIKY_SHIELD,   # + daño de retroceso al contacto
	KINGS_SHIELD,   # + baja Ataque del atacante en contacto
	BANEFUL_BUNKER, # + envenena al atacante en contacto
	OBSTRUCT,       # + baja mucho la Defensa del atacante en contacto
	WIDE_GUARD,     # bloquea cualquier movimiento dañino
	QUICK_GUARD,    # bloquea solo movimientos con prioridad > 0
	CRAFTY_SHIELD,  # bloquea solo movimientos de estado
}

const _MOVE_KIND: Dictionary = {
	Moves.MoveId.MOVE_PROTECT: Kind.BASIC,
	Moves.MoveId.MOVE_DETECT: Kind.BASIC,
	Moves.MoveId.MOVE_MAT_BLOCK: Kind.BASIC,
	Moves.MoveId.MOVE_SPIKY_SHIELD: Kind.SPIKY_SHIELD,
	Moves.MoveId.MOVE_KINGS_SHIELD: Kind.KINGS_SHIELD,
	Moves.MoveId.MOVE_BANEFUL_BUNKER: Kind.BANEFUL_BUNKER,
	Moves.MoveId.MOVE_OBSTRUCT: Kind.OBSTRUCT,
	Moves.MoveId.MOVE_WIDE_GUARD: Kind.WIDE_GUARD,
	Moves.MoveId.MOVE_QUICK_GUARD: Kind.QUICK_GUARD,
	Moves.MoveId.MOVE_CRAFTY_SHIELD: Kind.CRAFTY_SHIELD,
}


static func is_protect_move(move: MoveData) -> bool:
	return move != null and (
		move.effect == MoveStruct.MoveEffect.EFFECT_PROTECT
		or move.effect == MoveStruct.MoveEffect.EFFECT_ENDURE
	)


static func kind_for(move: MoveData) -> Kind:
	if move == null or move.effect != MoveStruct.MoveEffect.EFFECT_PROTECT:
		return Kind.NONE
	return _MOVE_KIND.get(move.move_id, Kind.BASIC)


## Probabilidad de éxito según usos consecutivos (1, 1/3, 1/9... desde Gen 5).
static func success_chance(protect_counter: int) -> float:
	return 1.0 / pow(3.0, float(clampi(protect_counter, 0, 8)))


static func blocks_move(kind: Kind, move: MoveData) -> bool:
	match kind:
		Kind.BASIC, Kind.SPIKY_SHIELD, Kind.KINGS_SHIELD, Kind.BANEFUL_BUNKER, Kind.OBSTRUCT, Kind.WIDE_GUARD:
			return true
		Kind.QUICK_GUARD:
			return move.priority > 0
		Kind.CRAFTY_SHIELD:
			return move.category == MoveStruct.DamageCategory.STATUS
	return false
