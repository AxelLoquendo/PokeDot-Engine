@tool
extends RefCounted

class_name RuntimeIndexGenerator

const OUTPUT_PATH: String = "res://data_core/generated/resource_index.gd"
const SPECIES_PATH: String = "res://data_core/pokemon/resources/"
const MOVE_PATH: String = "res://data_core/move/resources/"
const ABILITY_PATH: String = "res://data_core/ability/resources/"
const ITEM_PATH: String = "res://data_core/items/resources/"
const FILE_EXTENSION: String = ".tres"

func generate() -> Error:
	_form_index.clear()
	var paths: Dictionary = {
		"species": {},
		"forms": {},
		"moves": {},
		"abilities": {},
		"items": {},
	}
	var errors: Array[String] = []

	_scan_resources(SPECIES_PATH, "species_id", paths["species"], errors, true)
	_scan_resources(MOVE_PATH, "move_id", paths["moves"], errors)
	_scan_resources(ABILITY_PATH, "id", paths["abilities"], errors)
	_scan_resources(ITEM_PATH, "item_id", paths["items"], errors)

	if not errors.is_empty():
		for error: String in errors:
			push_warning("RuntimeIndex: %s" % error)

	var content: String = _build_script(paths)
	var file: FileAccess = FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_string(content)
	file.close()
	print(
		"RuntimeIndex: generado (%d especies, %d formas, %d movimientos, %d habilidades, %d ítems)." % [
			paths["species"].size(), paths["forms"].size(), paths["moves"].size(),
			paths["abilities"].size(), paths["items"].size()
		]
	)
	return OK

func _scan_resources(
	path: String,
	property_name: String,
	output: Dictionary,
	errors: Array[String],
	index_forms: bool = false
) -> void:
	for entry: String in ResourceLoader.list_directory(path):
		if entry.begins_with("."):
			continue
		var full_path: String = path.path_join(entry)
		if entry.ends_with("/"):
			_scan_resources(full_path, property_name, output, errors, index_forms)
		elif entry.ends_with(FILE_EXTENSION):
			var resource: Resource = ResourceLoader.load(full_path)
			if resource == null:
				errors.append("No se pudo cargar %s" % full_path)
				continue
			var id_value: Variant = resource.get(property_name)
			if id_value == null:
				errors.append("%s no tiene %s" % [full_path, property_name])
				continue
			var id: int = int(id_value)
			if id <= 0:
				errors.append("%s tiene un ID inválido: %d" % [full_path, id])
				continue
			if output.has(id):
				errors.append("ID duplicado %d: %s y %s" % [id, str(output[id]), full_path])
				continue
			output[id] = full_path

			if index_forms and resource is PokemonDataStruct:
				var species: PokemonDataStruct = resource as PokemonDataStruct
				for form: PokemonFormData in species.forms:
					if form == null or int(form.species_id) <= 0:
						continue
					# Las formas apuntan al recurso base que contiene el subrecurso.
					var form_index: Dictionary = _get_form_index()
					form_index[int(form.species_id)] = full_path

func _get_form_index() -> Dictionary:
	# Se inicializa una sola vez durante la generación.
	if not _form_index.is_empty():
		return _form_index
	_form_index = {}
	return _form_index

var _form_index: Dictionary = {}

func _build_script(paths: Dictionary) -> String:
	# Las formas se agregan al mapa antes de serializarlo.
	paths["forms"] = _form_index.duplicate()
	var lines: PackedStringArray = []
	lines.append("@tool")
	lines.append("extends RefCounted")
	lines.append("")
	lines.append("class_name RuntimeResourceIndex")
	lines.append("")
	lines.append("const PATHS: Dictionary = {")
	for kind: String in ["species", "forms", "moves", "abilities", "items"]:
		lines.append("\t\"%s\": {" % kind)
		var ids: Array[int] = []
		for id: int in paths[kind].keys():
			ids.append(id)
		ids.sort()
		for id: int in ids:
			lines.append("\t\t%d: \"%s\"," % [id, _escape(str(paths[kind][id]))])
		lines.append("\t},")
	lines.append("}")
	lines.append("")
	lines.append("func get_paths(kind: String) -> Dictionary:")
	lines.append("\tvar value: Variant = PATHS.get(kind, {})")
	lines.append("\treturn value.duplicate() as Dictionary if value is Dictionary else {}")
	lines.append("")
	return "\n".join(lines) + "\n"

func _escape(value: String) -> String:
	return value.replace("\\", "\\\\").replace("\"", "\\\"")
