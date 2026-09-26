@tool
extends RefCounted
class_name ContentChecker

## Revisa flags, entrenadores y mapas sin ejecutar el juego.

const SKIPPED_DIRS: Array[String] = ["res://addons", "res://.godot", "res://graphics", "res://sfx"]

var errors: Array[String] = []
var warnings: Array[String] = []

## flag -> ["ruta:línea", ...]
var _flag_setters: Dictionary = {}
var _flag_readers: Dictionary = {}
var _trainer_refs: Array[Array] = []  # [trainer_id, "ruta:línea"]


func run() -> void:
	errors.clear()
	warnings.clear()
	_flag_setters.clear()
	_flag_readers.clear()
	_trainer_refs.clear()

	for path: String in _find_files("res://", ["txt", "tscn", "tres", "gd"]):
		match path.get_extension():
			"txt":
				if not path.begins_with(TrainerDatabase.TRAINERS_DIR):
					_scan_script(path)
			"tscn", "tres":
				_scan_resource_text(path)
			"gd":
				_scan_code(path)

	_check_flags()
	_check_trainers()
	_check_maps()


func get_report() -> String:
	var lines: PackedStringArray = []
	for message: String in errors:
		lines.append("ERROR  " + message)
	for message: String in warnings:
		lines.append("AVISO  " + message)
	return "\n".join(lines)


# ------------------------------------------------------------
# Lectura
# ------------------------------------------------------------

func _scan_script(path: String) -> void:
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).replace("\r", "").split("\n")
	for index: int in lines.size():
		var words: PackedStringArray = lines[index].strip_edges().split(" ", false)
		if words.size() < 2 or words[0].begins_with("#") or words[0].begins_with("//"):
			continue
		var where: String = "%s:%d" % [path, index + 1]
		match words[0]:
			"setflag":
				_add(_flag_setters, words[1], where)
			"ifflag":
				_add(_flag_readers, words[1], where)
			"compare":
				if words[1] == "flag" and words.size() > 2:
					_add(_flag_readers, words[2], where)
			"trainerbattle":
				var trainer_id: String = words[1].to_upper()
				_add(_flag_setters, trainer_id, where)
				_add(_flag_readers, trainer_id, where)
				_trainer_refs.append([trainer_id, where])
			"warp":
				var section: String = words[1].to_upper()
				if not MapSection.SectionId.has(section):
					errors.append("%s: warp a %s, que no existe en MapSection." % [where, words[1]])
				elif not MapSection.is_registered(int(MapSection.SectionId[section])):
					errors.append("%s: warp a %s, que no tiene escena registrada." % [where, section])


func _scan_resource_text(path: String) -> void:
	var text: String = FileAccess.get_file_as_string(path)
	if not text.contains("flag") and not text.contains("dest_map") and not text.contains("target_section"):
		return
	var lines: PackedStringArray = text.split("\n")
	var flag_regex: RegEx = RegEx.create_from_string("^(condition_flag|required_flag|hidden_item_flag|flag_name) = &?\"([^\"]+)\"")
	var map_regex: RegEx = RegEx.create_from_string("^(dest_map|target_section) = (\\d+)")
	for index: int in lines.size():
		var where: String = "%s:%d" % [path, index + 1]
		var found: RegExMatch = flag_regex.search(lines[index])
		if found:
			var flag: String = found.get_string(2)
			match found.get_string(1):
				"condition_flag", "required_flag":
					_add(_flag_readers, flag, where)
				_:
					# hidden_item_flag o flag_name: cuentan como ambas cosas
					_add(_flag_setters, flag, where)
					_add(_flag_readers, flag, where)
			continue
		var map_found: RegExMatch = map_regex.search(lines[index])
		if map_found:
			var section_id: int = int(map_found.get_string(2))
			if section_id > 0 and not MapSection.is_registered(section_id):
				errors.append("%s: %s apunta a %s, que no tiene escena registrada." % [
					where, map_found.get_string(1), str(MapSection.SectionId.find_key(section_id))
				])


## global_flags["FLAG_X"] en el código.
func _scan_code(path: String) -> void:
	var text: String = FileAccess.get_file_as_string(path)
	if not text.contains("global_flag"):
		return
	var setter_regex: RegEx = RegEx.create_from_string("global_flags\\[\\s*\"([^\"]+)\"\\s*\\]\\s*=[^=]|set_global_flag\\(\\s*\"([^\"]+)\"")
	var reader_regex: RegEx = RegEx.create_from_string("global_flags\\.(?:get|has)\\(\\s*\"([^\"]+)\"|get_global_flag\\(\\s*\"([^\"]+)\"")
	var lines: PackedStringArray = text.split("\n")
	for index: int in lines.size():
		var where: String = "%s:%d" % [path, index + 1]
		for found: RegExMatch in setter_regex.search_all(lines[index]):
			_add(_flag_setters, _first_group(found), where)
		for found: RegExMatch in reader_regex.search_all(lines[index]):
			_add(_flag_readers, _first_group(found), where)


# ------------------------------------------------------------
# Comprobaciones
# ------------------------------------------------------------

func _check_flags() -> void:
	var all_flags: Array[String] = []
	for flag: String in _flag_setters.keys():
		all_flags.append(flag)
	for flag: String in _flag_readers.keys():
		if not all_flags.has(flag):
			all_flags.append(flag)
	all_flags.sort()
	for flag: String in all_flags:
		if not _flag_setters.has(flag):
			errors.append("%s: se comprueba %s, pero nada la activa.%s" % [
				(_flag_readers[flag] as Array)[0], flag, _similar_flag(flag, _flag_setters)
			])
		elif not _flag_readers.has(flag):
			warnings.append("%s: se activa %s, pero nunca se comprueba.%s" % [
				(_flag_setters[flag] as Array)[0], flag, _similar_flag(flag, _flag_readers)
			])


func _check_trainers() -> void:
	TrainerDatabase.reload()
	errors.append_array(TrainerDatabase.get_errors())
	warnings.append_array(TrainerDatabase.get_warnings())
	for reference: Array in _trainer_refs:
		var trainer_id: String = str(reference[0])
		if not TrainerDatabase.has_trainer(trainer_id):
			errors.append("%s: trainerbattle %s, pero ese entrenador no existe en %s." % [
				reference[1], trainer_id, TrainerDatabase.TRAINERS_DIR
			])


func _check_maps() -> void:
	var generator: MapRegistryGenerator = MapRegistryGenerator.new()
	if generator.generate() != OK:
		errors.append("%s: no se pudo escribir el registro de mapas." % MapRegistryGenerator.OUTPUT_PATH)
	warnings.append_array(generator.warnings)


# ------------------------------------------------------------
# Utilidades
# ------------------------------------------------------------

func _similar_flag(flag: String, candidates: Dictionary) -> String:
	var best: String = ""
	var best_score: float = 0.8
	for candidate: String in candidates.keys():
		var score: float = candidate.similarity(flag)
		if candidate != flag and score > best_score:
			best_score = score
			best = candidate
	return "" if best.is_empty() else " ¿Quisiste decir %s?" % best


func _add(target: Dictionary, key: String, where: String) -> void:
	if key.is_empty():
		return
	if not target.has(key):
		target[key] = []
	(target[key] as Array).append(where)


func _first_group(found: RegExMatch) -> String:
	for group: int in range(1, found.get_group_count() + 1):
		if not found.get_string(group).is_empty():
			return found.get_string(group)
	return ""


func _find_files(dir_path: String, extensions: Array[String]) -> Array[String]:
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
				found.append_array(_find_files(full_path, extensions))
		elif extensions.has(entry.get_extension()):
			found.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	return found
