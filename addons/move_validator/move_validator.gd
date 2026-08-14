@tool
extends EditorPlugin


const MOVE_PATH: String = "res://data_core/move/resources/"
const MOVE_EXTENSION: String = ".tres"


func _enter_tree() -> void:
	add_tool_menu_item(
		"Validate Moves",
		_validate_all
	)


func _exit_tree() -> void:
	remove_tool_menu_item(
		"Validate Moves"
	)


func _validate_all() -> void:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var found_ids: Dictionary = {}

	var root_dir: DirAccess = DirAccess.open(MOVE_PATH)

	if root_dir == null:
		var message := (
			"MoveValidator: No se pudo abrir '%s'."
			% MOVE_PATH
		)

		push_error(message)
		return

	root_dir.list_dir_end()


	# ============================================================
	# RECORRER TODOS LOS RECURSOS
	# ============================================================

	var counters: Dictionary = _validate_folder(
		MOVE_PATH,
		found_ids,
		errors,
		warnings
	)

	var total_files: int = counters["total_files"]
	var valid_files: int = counters["valid_files"]


	# ============================================================
	# BUSCAR IDs FALTANTES
	# ============================================================

	var missing_ids: Array[String] = []

	var enum_names: Array[String] = Moves.MoveId.keys()
	var enum_values: Array[int] = Moves.MoveId.values()

	for i in range(enum_names.size()):

		var move_id: int = enum_values[i]
		var move_name: String = enum_names[i]

		if move_id == Moves.MoveId.MOVE_NONE:
			continue

		if not found_ids.has(move_id):
			missing_ids.append(move_name)


	# ============================================================
	# RESULTADO
	# ============================================================

	print("")
	print("════════════════════════════════════")
	print("          MOVE VALIDATOR")
	print("════════════════════════════════════")

	print(
		"Archivos encontrados : %d"
		% total_files
	)

	print(
		"Archivos válidos     : %d"
		% valid_files
	)

	print(
		"Archivos inválidos   : %d"
		% (total_files - valid_files)
	)

	print(
		"Errores              : %d"
		% errors.size()
	)

	print(
		"Advertencias         : %d"
		% warnings.size()
	)

	print(
		"IDs faltantes        : %d"
		% missing_ids.size()
	)


	# ============================================================
	# ERRORES
	# ============================================================

	if not errors.is_empty():

		print("")
		print("── ERRORES ──────────────────────────")

		for error: String in errors:
			push_error(
				"MoveValidator: %s"
				% error
			)


	# ============================================================
	# ADVERTENCIAS
	# ============================================================

	if not warnings.is_empty():

		print("")
		print("── ADVERTENCIAS ─────────────────────")

		for warning: String in warnings:
			print(
				"MoveValidator: %s"
				% warning
			)


	# ============================================================
	# IDs FALTANTES
	# ============================================================

	if not missing_ids.is_empty():

		print("")
		print(
			"── IDs SIN RECURSO (%d) ─────────────"
			% missing_ids.size()
		)

		for move_name: String in missing_ids:
			print(
				"  - %s"
				% move_name
			)


	# ============================================================
	# RESULTADO FINAL
	# ============================================================

	print("")

	if (
		errors.is_empty()
		and warnings.is_empty()
		and missing_ids.is_empty()
	):
		print("✓ Todos los movimientos son válidos.")
	else:
		print("✖ Se encontraron problemas.")

	print("════════════════════════════════════")
	print("")


# ============================================================
# RECORRIDO RECURSIVO
# ============================================================

func _validate_folder(
	path: String,
	found_ids: Dictionary,
	errors: Array[String],
	warnings: Array[String]
) -> Dictionary:

	var counters := {
		"total_files": 0,
		"valid_files": 0
	}

	var dir: DirAccess = DirAccess.open(path)

	if dir == null:

		errors.append(
			"No se pudo abrir la carpeta '%s'."
			% path
		)

		return counters


	dir.list_dir_begin()

	var entry: String = dir.get_next()

	while entry != "":

		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue


		# ========================================================
		# SUBCARPETA
		# ========================================================

		if dir.current_is_dir():

			var child_counters: Dictionary = _validate_folder(
				path.path_join(entry),
				found_ids,
				errors,
				warnings
			)

			counters["total_files"] += (
				child_counters["total_files"]
			)

			counters["valid_files"] += (
				child_counters["valid_files"]
			)


		# ========================================================
		# RECURSO
		# ========================================================

		elif entry.ends_with(MOVE_EXTENSION):

			counters["total_files"] += 1

			var full_path: String = (
				path.path_join(entry)
			)

			if _validate_move_file(
				full_path,
				found_ids,
				errors,
				warnings
			):
				counters["valid_files"] += 1


		entry = dir.get_next()

	dir.list_dir_end()

	return counters


# ============================================================
# VALIDAR UN MOVIMIENTO
# ============================================================

func _validate_move_file(
	path: String,
	found_ids: Dictionary,
	errors: Array[String],
	warnings: Array[String]
) -> bool:

	var resource: Resource = load(path)


	# ============================================================
	# CARGA
	# ============================================================

	if resource == null:

		errors.append(
			"'%s': no se pudo cargar el recurso."
			% path
		)

		return false


	# ============================================================
	# TIPO
	# ============================================================

	if not resource is MoveData:

		errors.append(
			"'%s': el recurso no es MoveData."
			% path
		)

		return false


	var data: MoveData = resource as MoveData


	# ============================================================
	# ID
	# ============================================================

	if data.move_id == Moves.MoveId.MOVE_NONE:

		errors.append(
			"'%s': move_id = MOVE_NONE."
			% path
		)

		return false


	# ============================================================
	# ID INVÁLIDO
	# ============================================================

	if not _enum_contains_value(
		Moves.MoveId,
		data.move_id
	):

		errors.append(
			"'%s': move_id %d no existe en Moves.MoveId."
			% [
				path,
				data.move_id
			]
		)

		return false


	# ============================================================
	# ID DUPLICADO
	# ============================================================

	if found_ids.has(data.move_id):

		var previous_path: String = (
			found_ids[data.move_id] as String
		)

		errors.append(
			"ID duplicado %d: '%s' y '%s'."
			% [
				data.move_id,
				previous_path,
				path
			]
		)

		return false


	found_ids[data.move_id] = path


	# ============================================================
	# VALIDACIÓN INTERNA
	# ============================================================

	var validation_errors: Array[String] = (
		data._validate()
	)

	if not validation_errors.is_empty():

		for validation_error: String in validation_errors:

			errors.append(
				"'%s': %s"
				% [
					path,
					validation_error
				]
			)

		return false


	# ============================================================
	# ADVERTENCIAS SEMÁNTICAS
	# ============================================================

	_validate_warnings(
		data,
		path,
		warnings
	)


	return true


# ============================================================
# ADVERTENCIAS
# ============================================================

func _validate_warnings(
	data: MoveData,
	path: String,
	warnings: Array[String]
) -> void:

	# ------------------------------------------------------------
	# Accuracy
	# ------------------------------------------------------------

	if data.accuracy == 0 and not data.always_hits:

		warnings.append(
			"'%s': accuracy = 0 pero always_hits = false."
			% path
		)


	# ------------------------------------------------------------
	# Multi-hit
	# ------------------------------------------------------------

	if data.is_multi_hit:

		if data.min_hits == data.max_hits:

			warnings.append("'%s': es multi-hit pero min_hits y max_hits, son iguales (%d)." % [path, data.min_hits])


	# ------------------------------------------------------------
	# Secondary chance
	# ------------------------------------------------------------

	if (data.secondary_effect == MoveStruct.SecondaryEffect.MOVE_EFFECT_NONE and data.secondary_chance > 0):

		# Esto ya es error en _validate(), así que realmente
		# no debería llegar aquí.
		return


# ============================================================
# UTILIDADES
# ============================================================

func _enum_contains_value(
	enum_dictionary: Dictionary,
	value: int
) -> bool:

	return value in enum_dictionary.values()
