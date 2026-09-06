extends Node
class_name AbilityDB

const ABILITIES_PATH: String = "res://data_core/ability/resources/"
const FILE_EXTENSION: String = ".tres"
const INDEX_SCRIPT = preload("res://data_core/generated/resource_index.gd")

var _cache: Dictionary = {}
var _paths: Dictionary = {}
var _loaded: bool = false
var _errors: Array[String] = []
var _warnings: Array[String] = []
var _enum_names: Array[String] = []

signal database_loaded(count: int)

func _ready() -> void:
	for key: String in AbilityId.Id.keys():
		_enum_names.append(key)
	load_database()

func get_ability(ability_id: AbilityId.Id) -> AbilityData:
	if not _loaded:
		push_error("AbilityDB: La base de datos no se ha cargado aún.")
		return null
	var id: int = int(ability_id)
	if _cache.has(id):
		return _cache[id] as AbilityData
	if _paths.has(id):
		_load_ability_file(str(_paths[id]))
	return _cache.get(id) as AbilityData

func has_ability(ability_id: AbilityId.Id) -> bool:
	if not _loaded:
		return false
	var id: int = int(ability_id)
	return _cache.has(id) or _paths.has(id)

func get_all_abilities() -> Array[AbilityData]:
	_ensure_all_loaded()
	var result: Array[AbilityData] = []
	for data: AbilityData in _cache.values():
		result.append(data)
	return result

func get_abilities_by_generation(gen: int) -> Array[AbilityData]:
	var result: Array[AbilityData] = []
	for data: AbilityData in get_all_abilities():
		if data.generation == gen:
			result.append(data)
	return result

func get_ability_name(ability_id: AbilityId.Id) -> String:
	var data: AbilityData = get_ability(ability_id)
	if data != null and not data.name_key.is_empty():
		return tr(data.name_key)
	var id_int: int = int(ability_id)
	if id_int < 0 or id_int >= _enum_names.size():
		return "???"
	return _enum_names[id_int].capitalize()

func get_ability_count() -> int:
	return _paths.size() if not _paths.is_empty() else _cache.size()

func get_load_errors() -> Array[String]:
	return _errors.duplicate()

func get_load_warnings() -> Array[String]:
	return _warnings.duplicate()

func reload_database() -> void:
	_cache.clear()
	_paths.clear()
	_errors.clear()
	_warnings.clear()
	_loaded = false
	load_database()

func load_database() -> void:
	var index: Dictionary = INDEX_SCRIPT.new().get_paths("abilities")
	if index.is_empty():
		# Compatibilidad si todavía no se ha generado el índice.
		_load_from_subfolder(ABILITIES_PATH)
	else:
		_paths = index.duplicate()
	_loaded = true
	database_loaded.emit(get_ability_count())
	print("AbilityDB: índice listo con %d habilidades; cargadas ahora: %d." % [get_ability_count(), _cache.size()])

func _ensure_all_loaded() -> void:
	for id: int in _paths.keys():
		if not _cache.has(id):
			_load_ability_file(str(_paths[id]))

func _load_from_subfolder(path: String) -> void:
	for entry: String in ResourceLoader.list_directory(path):
		if entry.begins_with("."):
			continue
		var full_path: String = path.path_join(entry)
		if entry.ends_with("/"):
			_load_from_subfolder(full_path)
		elif entry.ends_with(FILE_EXTENSION):
			_load_ability_file(full_path)

func _load_ability_file(path: String) -> void:
	var resource: Resource = load(path)
	if not resource is AbilityData:
		_errors.append("'%s' no es un AbilityData válido." % path)
		return
	var data: AbilityData = resource as AbilityData
	var id: int = int(data.id)
	if _cache.has(id):
		return
	var validation_errors: Array[String] = data._validate()
	if not validation_errors.is_empty():
		for err: String in validation_errors:
			_errors.append("'%s': %s" % [path.get_file(), err])
		return
	_cache[id] = data

func _debug_print_all() -> void:
	_ensure_all_loaded()
	print("═══ AbilityDB Debug ═══")
	for id_val: int in _cache.keys():
		var data: AbilityData = _cache[id_val] as AbilityData
		print("  [%d] %s" % [id_val, data.name_key])
	print("═══════════════════════")
