@tool
extends Resource
class_name MoveData


@export_group("Información Base")
@export var move_id: Moves.MoveId
@export var move_name: String
@export_multiline var description: String
@export var type: PokemonData.Type
@export var category: MoveStruct.DamageCategory
@export var target: MoveStruct.MoveTarget


@export_group("Parámetros Numéricos")
@export var power: int
@export var accuracy: int
@export var pp: int
@export var priority: int = 0
@export var crit_stage: int = 0
@export var min_hits: int = 1
@export var max_hits: int = 1
@export var drain_percent: int = 0
@export var recoil_percent: int = 0


@export_group("Flags Mecánicas de Combate")
@export var is_multi_hit: bool = false
@export var is_explosion: bool = false


@export_group("Efectos")
@export var effect: MoveStruct.MoveEffect
@export var secondary_effect: MoveStruct.SecondaryEffect
@export var secondary_chance: int = 0
@export var z_effect: MoveStruct.ZEffect


@export_group("Flags de Tipo de Movimiento")
@export var makes_contact: bool = false
@export var punching_move: bool = false
@export var biting_move: bool = false
@export var slicing_move: bool = false
@export var sound_move: bool = false
@export var ballistic_move: bool = false
@export var pulse_move: bool = false
@export var powder_move: bool = false
@export var wind_move: bool = false
@export var dance_move: bool = false
@export var healing_move: bool = false


@export_group("Flags de Interacción Extensas")
@export var magic_coat_affected: bool = false
@export var snatch_affected: bool = false
@export var ignores_kings_rock: bool = false
@export var thaws_user: bool = false
@export var force_pressure: bool = false
@export var cant_use_twice: bool = false


@export_group("Flags de Precisión y Evasión")
@export var always_hits: bool = false
@export var ignores_protect: bool = false
@export var ignores_substitute: bool = false
@export var always_critical: bool = false
@export var ignores_target_ability: bool = false
@export var ignores_target_defense_evasion_stages: bool = false


@export_group("Flags de Clima")
@export var always_hits_in_rain: bool = false
@export var always_hits_in_hail_snow: bool = false
@export var accuracy_50_in_sun: bool = false


@export_group("Flags de Estados Especiales del Rival")
@export var minimize_double_damage: bool = false
@export var damages_underground: bool = false
@export var damages_underwater: bool = false
@export var damages_airborne: bool = false
@export var damages_airborne_double_damage: bool = false


@export_group("Baneos")
@export var gravity_banned: bool = false
@export var mirror_move_banned: bool = false
@export var me_first_banned: bool = false
@export var mimic_banned: bool = false
@export var metronome_banned: bool = false
@export var copycat_banned: bool = false
@export var assist_banned: bool = false
@export var sleep_talk_banned: bool = false
@export var instruct_banned: bool = false
@export var encore_banned: bool = false
@export var parental_bond_banned: bool = false
@export var sky_battle_banned: bool = false
@export var sketch_banned: bool = false
@export var damp_banned: bool = false


func _validate() -> Array[String]:
	var errors: Array[String] = []


	# ============================================================
	# IDENTIDAD
	# ============================================================

	if move_id == Moves.MoveId.MOVE_NONE:
		errors.append(
			"El movimiento no puede tener MOVE_NONE."
		)

	if move_name.strip_edges().is_empty():
		errors.append(
			"move_name está vacío."
		)

	if description.strip_edges().is_empty():
		errors.append(
			"description está vacío."
		)


	# ============================================================
	# ENUMERACIONES
	# ============================================================

	if not _enum_contains_value(Moves.MoveId, move_id):
		errors.append(
			"move_id tiene un valor inválido: %d."
			% move_id
		)

	if not _enum_contains_value(PokemonData.Type, type):
		errors.append(
			"type tiene un valor inválido: %d."
			% type
		)

	if not _enum_contains_value(MoveStruct.DamageCategory, category):
		errors.append(
			"category tiene un valor inválido: %d."
			% category
		)

	if not _enum_contains_value(MoveStruct.MoveTarget, target):
		errors.append(
			"target tiene un valor inválido: %d."
			% target
		)

	if not _enum_contains_value(MoveStruct.MoveEffect, effect):
		errors.append(
			"effect tiene un valor inválido: %d."
			% effect
		)

	if not _enum_contains_value(
		MoveStruct.SecondaryEffect,
		secondary_effect
	):
		errors.append(
			"secondary_effect tiene un valor inválido: %d."
			% secondary_effect
		)

	if not _enum_contains_value(MoveStruct.ZEffect, z_effect):
		errors.append(
			"z_effect tiene un valor inválido: %d."
			% z_effect
		)


	# ============================================================
	# PARÁMETROS NUMÉRICOS
	# ============================================================

	if power < 0:
		errors.append(
			"power no puede ser negativo."
		)

	# En Pokémon, accuracy = 0 puede representar un movimiento
	# que no utiliza la comprobación normal de precisión.
	if accuracy < 0 or accuracy > 100:
		errors.append(
			"accuracy debe estar entre 0 y 100."
		)

	if pp < 1:
		errors.append(
			"pp debe ser mayor o igual a 1."
		)

	if priority < -7 or priority > 7:
		errors.append(
			"priority está fuera del rango permitido (-7 a 7)."
		)

	if crit_stage < 0:
		errors.append(
			"crit_stage no puede ser negativo."
		)

	if min_hits < 1:
		errors.append(
			"min_hits debe ser mayor o igual a 1."
		)

	if max_hits < 1:
		errors.append(
			"max_hits debe ser mayor o igual a 1."
		)

	if min_hits > max_hits:
		errors.append(
			"min_hits no puede ser mayor que max_hits."
		)

	if drain_percent < 0 or drain_percent > 100:
		errors.append(
			"drain_percent debe estar entre 0 y 100."
		)

	if recoil_percent < 0 or recoil_percent > 100:
		errors.append(
			"recoil_percent debe estar entre 0 y 100."
		)

	if secondary_chance < 0 or secondary_chance > 100:
		errors.append(
			"secondary_chance debe estar entre 0 y 100."
		)


	# ============================================================
	# MULTI-HIT
	# ============================================================

	if is_multi_hit:
		if min_hits < 2:
			errors.append(
				"Un movimiento multi-hit debe tener min_hits >= 2."
			)

		if max_hits < 2:
			errors.append(
				"Un movimiento multi-hit debe tener max_hits >= 2."
			)

	else:
		if min_hits != 1 or max_hits != 1:
			errors.append("Un movimiento que no es multi-hit debe tener, min_hits = 1 y max_hits = 1.")


	# ============================================================
	# EFECTOS SECUNDARIOS
	# ============================================================

	if secondary_effect == MoveStruct.SecondaryEffect.MOVE_EFFECT_NONE:
		if secondary_chance != 0:
			errors.append("secondary_chance debe ser 0 cuando, no existe secondary_effect.")


	# ============================================================
	# EFECTO PRINCIPAL
	# ============================================================

	if effect == MoveStruct.MoveEffect.EFFECT_NONE:
		errors.append(
			"El movimiento tiene EFFECT_NONE."
		)


	# ============================================================
	# OBJETIVO
	# ============================================================

	if target == MoveStruct.MoveTarget.TARGET_NONE:
		errors.append(
			"El movimiento debe tener un objetivo válido."
		)


	return errors


static func _enum_contains_value(
	enum_dictionary: Dictionary,
	value: int
) -> bool:
	return value in enum_dictionary.values()
