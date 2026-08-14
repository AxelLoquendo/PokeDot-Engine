@tool
extends EditorPlugin

const ABILITIES_PATH: String = "res://data_core/ability/resources/"

func _enter_tree() -> void:
	add_tool_menu_item("Validate Abilities", _validate_all)

func _exit_tree() -> void:
	remove_tool_menu_item("Validate Abilities")


func _validate_all() -> void:
	var stats: Dictionary = {"total": 0}
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var seen_ids: Dictionary = {}

	var dir: DirAccess = DirAccess.open(ABILITIES_PATH)
	if not dir:
		push_error("No se encontró la carpeta: " + ABILITIES_PATH)
		return

	_validate_folder(ABILITIES_PATH, stats, errors, warnings, seen_ids)

	var missing_ids: Array[String] = []
	var enum_nombres: Array[String] = AbilityId.Id.keys()
	var enum_valores: Array[int] = AbilityId.Id.values()

	for i: int in range(enum_nombres.size()):
		var valor_id: int = enum_valores[i]
		var nombre_clave: String = enum_nombres[i]
		if (valor_id != AbilityId.Id.NONE and valor_id != AbilityId.Id.COUNT and not seen_ids.has(valor_id)):
			missing_ids.append(nombre_clave)

	print("═══ Validación de Habilidades ═══")
	print("Total archivos encontrados: %d" % stats.total)

	if errors.is_empty() and warnings.is_empty() and missing_ids.is_empty():
		print("Todo correcto. Sin errores ni advertencias.")
	else:
		for e: String in errors:
			push_error("ERROR: %s" % e)
		for w: String in warnings:
			print("WARNING: %s" % w)
		if not missing_ids.is_empty():
			print("IDs sin archivo .tres (%d):" % missing_ids.size())
			for m: String in missing_ids:
				print("     - %s" % m)
	print("═════════════════════════════════")


func _validate_folder(path: String, stats: Dictionary, errors: Array[String], warnings: Array[String], seen_ids: Dictionary) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			_validate_folder(path.path_join(file_name), stats, errors, warnings, seen_ids)
		elif file_name.ends_with(".tres"):
			stats.total += 1
			var full_path: String = path.path_join(file_name)
			var recurso_cargado: Resource = load(full_path)

			if not recurso_cargado is AbilityData:
				errors.append("'%s' no es AbilityData." % file_name)
			else:
				var data: AbilityData = recurso_cargado as AbilityData
				if data.id == AbilityId.Id.COUNT:
					errors.append("'%s': ID = COUNT." % file_name)
				elif seen_ids.has(data.id):
					errors.append("'%s': ID %d duplicado." % [file_name, data.id])
				else:
					seen_ids[data.id] = true

				# Reusa la misma validación que corre AbilityDB al cargar,
				# así el plugin y el runtime nunca quedan desincronizados
				for err: String in data._validate():
					errors.append("'%s': %s" % [file_name, err])

		file_name = dir.get_next()
	dir.list_dir_end()
