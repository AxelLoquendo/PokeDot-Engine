@tool
extends RefCounted

class_name MapRegistryGenerator

## Genera map_registry.gd (MAPSEC -> escena) con las escenas cuyo nodo raíz
## tiene map_id_section.

const OUTPUT_PATH: String = "res://data_core/generated/map_registry.gd"
const SECTION_SCRIPT_PATH: String = "res://data_core/scripts/map/map_section.gd"
const SKIPPED_DIRS: Array[String] = ["res://addons", "res://.godot"]
const ACCENTS: Dictionary = {
	"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U", "Ñ": "N",
}

## Avisos de la última generación.
var warnings: Array[String] = []


func generate() -> Error:
	warnings.clear()
	var sections: Dictionary = read_section_enum()
	var keys_by_id: Dictionary = {}
	for key: String in sections.keys():
		keys_by_id[int(sections[key])] = key

	var maps: Dictionary = {}
	for path: String in _find_scenes("res://"):
		var root: Dictionary = read_map_root(path)
		if root.is_empty():
			continue
		var id: int = int(root["id"])
		if id <= 0:
			continue
		if not keys_by_id.has(id):
			warnings.append("%s usa map_id_section = %d, que no existe en MapSection.SectionId." % [path, id])
			continue
		if maps.has(id):
			warnings.append("%s está repetido en %s y %s; se usa el primero." % [
				keys_by_id[id], (maps[id] as Dictionary)["path"], path
			])
			continue
		maps[id] = {"key": keys_by_id[id], "name": root["name"], "path": path}

	for warning: String in warnings:
		push_warning("MapRegistry: %s" % warning)
	var content: String = _build_script(maps)
	if FileAccess.file_exists(OUTPUT_PATH) and FileAccess.get_file_as_string(OUTPUT_PATH) == content:
		return OK
	var file: FileAccess = FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_string(content)
	file.close()
	print("MapRegistry: %d mapas registrados." % maps.size())
	return OK


## Se lee del archivo porque el editor puede no haber recargado el script.
static func read_section_enum() -> Dictionary:
	var result: Dictionary = {}
	var text: String = FileAccess.get_file_as_string(SECTION_SCRIPT_PATH)
	var start: int = text.find("enum SectionId {")
	if start < 0:
		return result
	var end: int = text.find("\n}", start)
	if end < 0:
		end = text.length()
	var regex: RegEx = RegEx.create_from_string("(MAPSEC_[A-Z0-9_]+)\\s*=\\s*(\\d+)")
	for found: RegExMatch in regex.search_all(text.substr(start, end - start)):
		result[found.get_string(1)] = int(found.get_string(2))
	return result


## Devuelve el valor asignado, el existente si ya estaba, o -1.
static func add_section(key: String) -> int:
	var sections: Dictionary = read_section_enum()
	if sections.has(key):
		return int(sections[key])
	var next_value: int = 1
	for value: int in sections.values():
		next_value = maxi(next_value, value + 1)

	var text: String = FileAccess.get_file_as_string(SECTION_SCRIPT_PATH)
	var start: int = text.find("enum SectionId {")
	var end: int = text.find("\n}", start) if start >= 0 else -1
	if end < 0:
		return -1
	text = text.insert(end, "\n\t%s = %d," % [key, next_value])
	var file: FileAccess = FileAccess.open(SECTION_SCRIPT_PATH, FileAccess.WRITE)
	if file == null:
		return -1
	file.store_string(text)
	file.close()
	return next_value


## "Cueva Ámbar" = MAPSEC_CUEVA_AMBAR
static func make_section_key(display_name: String) -> String:
	var plain: String = display_name.to_upper()
	for accented: String in ACCENTS.keys():
		plain = plain.replace(accented, ACCENTS[accented])
	var result: String = ""
	for character: String in plain:
		var code: int = character.unicode_at(0)
		if (code >= 65 and code <= 90) or (code >= 48 and code <= 57):
			result += character
		elif not result.is_empty() and not result.ends_with("_"):
			result += "_"
	result = result.trim_suffix("_")
	return "" if result.is_empty() else "MAPSEC_" + result


## {} si la escena no es un mapa con MAPSEC.
static func read_map_root(path: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(path)
	if not text.contains("map_id_section"):
		return {}
	var result: Dictionary = {}
	var in_root: bool = false
	for line: String in text.split("\n"):
		if line.begins_with("["):
			if in_root:
				break
			in_root = line.begins_with("[node ") and not line.contains(" parent=")
			continue
		if not in_root:
			continue
		if line.begins_with("map_id_section = "):
			result["id"] = int(line.trim_prefix("map_id_section = "))
		elif line.begins_with("map_name = "):
			result["name"] = str(str_to_var(line.trim_prefix("map_name = ")))
	if not result.has("id"):
		return {}
	if not result.has("name"):
		result["name"] = ""
	return result


func _find_scenes(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with(".") and not SKIPPED_DIRS.has(full_path):
				found.append_array(_find_scenes(full_path))
		elif entry.ends_with(".tscn"):
			found.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	found.sort()
	return found


func _build_script(maps: Dictionary) -> String:
	var ids: Array[int] = []
	for id: int in maps.keys():
		ids.append(id)
	ids.sort()
	var lines: PackedStringArray = []
	lines.append("@tool")
	lines.append("extends RefCounted")
	lines.append("")
	lines.append("class_name MapRegistry")
	lines.append("")
	lines.append("## Generado por MapRegistryGenerator: no lo edites a mano.")
	lines.append("## Se actualiza al guardar un mapa o desde")
	lines.append("## \"Proyecto → Herramientas → Actualizar registro de mapas\".")
	lines.append("")
	lines.append("const MAPS: Dictionary = {")
	for id: int in ids:
		var entry: Dictionary = maps[id]
		lines.append("\t%d: {\"key\": %s, \"name\": %s, \"path\": %s}," % [
			id, var_to_str(str(entry["key"])), var_to_str(str(entry["name"])), var_to_str(str(entry["path"]))
		])
	lines.append("}")
	return "\n".join(lines) + "\n"
