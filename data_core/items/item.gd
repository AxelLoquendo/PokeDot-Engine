extends RefCounted
class_name ItemConstants

enum Pocket {
	POCKET_ITEMS = 0,
	POCKET_MEDICINE = 1,
	POCKET_POKE_BALLS = 2,
	POCKET_TMS_HMS = 3,
	POCKET_TMS = 4,
	POCKET_TM_MATERIALS = 5,
	POCKET_BATTLE_ITEMS = 6,
	POCKET_BERRIES = 7,
	POCKET_KEY_ITEMS = 8,
	POCKET_MAIL = 9,
	POCKET_MEGA_STONES = 10,
	POCKET_Z_CRYSTALS = 11,
	POCKET_ROTOM_POWERS = 12,
	POCKET_INGREDIENTS = 13,
	POCKET_TREASURES = 14,
	POCKET_PICNIC_ITEMS = 15,
	POCKET_CANDY = 16,
	POCKET_CATCHING = 17,
	POCKET_POWER_UP = 18,
	POCKET_OTHER = 19,

	POCKETS_COUNT = 20,
	POCKET_DUMMY = 20,
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
