extends RefCounted
class_name ItemConstants

enum Pocket {
	POCKET_ITEMS = 0,
	POCKET_POKE_BALLS = 1,
	POCKET_TM_HM = 2,
	POCKET_BERRIES = 3,
	POCKET_KEY_ITEMS = 4,
	POCKETS_COUNT = 5,
	POCKET_DUMMY = 5,
}

# Máscara de bits para Repelente/Cebo (Repel/Lure)
const REPEL_LURE_MASK: int = 1 << 15

# Funciones de utilidad para reemplazar las macros de C
static func is_last_used_lure(value: int) -> bool:
	return (value & REPEL_LURE_MASK) != 0

static func repel_lure_steps(value: int) -> int:
	return value & (REPEL_LURE_MASK - 1)

# En C, estas macros llamaban a VarGet(VAR_REPEL_STEP_COUNT). 
# En Godot, debes pasarle el valor de tu variable de guardado como argumento.
static func get_lure_step_count(repel_step_count: int) -> int:
	return repel_lure_steps(repel_step_count) if is_last_used_lure(repel_step_count) else 0

static func get_repel_step_count(repel_step_count: int) -> int:
	return repel_lure_steps(repel_step_count) if not is_last_used_lure(repel_step_count) else 0

# Asumiendo Gen 9 para I_SELL_VALUE_FRACTION (4). Si usas Gen 8 o inferior, cámbialo a 2.
const ITEM_SELL_FACTOR: int = 4
