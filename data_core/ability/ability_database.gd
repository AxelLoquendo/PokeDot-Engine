extends Node
class_name AbilityDB

## Autoload singleton que gestiona todas las habilidades.
## Regístralo en Project Settings → Autoload como "AbilityDB"

## ─── Configuración ──────────────────────────────────────
const ABILITIES_PATH: String = "res://data_core/ability/resources/"
const FILE_EXTENSION: String = ".tres"

## ─── Estado ─────────────────────────────────────────────
var _cache: Dictionary = {}
var _loaded: bool = false
var _errors: Array[String] = []
var _warnings: Array[String] = []
var _enum_names: Array[String] = []  # cache de AbilityId.Id.keys()

## ─── Señales ────────────────────────────────────────────
signal database_loaded(count: int)
signal database_error(message: String)

## ─── Ciclo de vida ──────────────────────────────────────
func _ready() -> void:
	_enum_names = []
	for key: String in AbilityId.Id.keys():
		_enum_names.append(key)

	load_database()

## ─── API Pública ────────────────────────────────────────

func get_ability(ability_id: AbilityId.Id) -> AbilityData:
	if not _loaded:
		push_error("AbilityDB: La base de datos no se ha cargado aún.")
		return null

	if _cache.has(ability_id):
		return _cache[ability_id] as AbilityData

	push_warning("AbilityDB: Habilidad %d no encontrada." % ability_id)
	return null


func has_ability(ability_id: AbilityId.Id) -> bool:
	if not _loaded:
		push_warning("AbilityDB: La base de datos no se ha cargado aún.")
		return false
	return _cache.has(ability_id)


func get_all_abilities() -> Array[AbilityData]:
	var result: Array[AbilityData] = []
	for data: AbilityData in _cache.values():
		result.append(data)
	return result


func get_abilities_by_generation(gen: int) -> Array[AbilityData]:
	var result: Array[AbilityData] = []
	for data: AbilityData in _cache.values():
		if data.generation == gen:
			result.append(data)
	return result


func get_ability_name(ability_id: AbilityId.Id) -> String:
	var data: AbilityData = get_ability(ability_id)
	if data and not data.name_key.is_empty():
		return tr(data.name_key)

	var id_int: int = ability_id
	if id_int < 0 or id_int >= _enum_names.size():
		return "???"
	return _enum_names[id_int].capitalize()


func get_ability_count() -> int:
	return _cache.size()


func get_load_errors() -> Array[String]:
	return _errors


func get_load_warnings() -> Array[String]:
	return _warnings


func reload_database() -> void:
	_cache.clear()
	_errors.clear()
	_warnings.clear()
	_loaded = false
	load_database()


## ─── Carga interna ──────────────────────────────────────
func load_database() -> void:
	var dir: DirAccess = DirAccess.open(ABILITIES_PATH)

	if not dir:
		var msg: String = "AbilityDB: No se pudo abrir '%s'" % ABILITIES_PATH
		_errors.append(msg)
		database_error.emit(msg)
		push_error(msg)
		return

	dir.list_dir_begin()
	var entry: String = dir.get_next()

	while entry != "":
		if dir.current_is_dir():
			var ruta_completa: String = ABILITIES_PATH.path_join(entry)
			_load_from_subfolder(ruta_completa)
		entry = dir.get_next()

	dir.list_dir_end()

	_loaded = true
	database_loaded.emit(_cache.size())

	print("AbilityDB: %d habilidades cargadas." % _cache.size())

	if not _warnings.is_empty():
		print("AbilityDB: %d advertencias:" % _warnings.size())
		for w: String in _warnings:
			print("  ⚠ %s" % w)

	if not _errors.is_empty():
		print("AbilityDB: %d errores:" % _errors.size())
		for e: String in _errors:
			push_error("%s" % e)


func _load_from_subfolder(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()

	while file_name != "":
		if dir.current_is_dir():
			# soporta subcarpetas anidadas (ej. resources/gen1/status/)
			_load_from_subfolder(path.path_join(file_name))
		elif file_name.ends_with(FILE_EXTENSION):
			var ruta_archivo: String = path.path_join(file_name)
			_load_ability_file(ruta_archivo)
		file_name = dir.get_next()

	dir.list_dir_end()


func _load_ability_file(path: String) -> void:
	var recurso_cargado: Resource = load(path)

	if not recurso_cargado is AbilityData:
		_errors.append("'%s' no es un AbilityData válido." % path)
		return

	var data: AbilityData = recurso_cargado as AbilityData

	if _cache.has(data.id):
		var existing_path: String = (_cache[data.id] as AbilityData).resource_path
		_errors.append("ID %d duplicado: '%s' vs '%s'" % [data.id, existing_path, path])
		return

	var validation_errors: Array[String] = data._validate()

	if not validation_errors.is_empty():
		var nombre_archivo: String = path.get_file()

		for err: String in validation_errors:
			_errors.append("'%s': %s" % [nombre_archivo, err])

		return

	_cache[data.id] = data


## ─── Debug ───────────────────────────────────────────────
func _debug_print_all() -> void:
	print("═══ AbilityDB Debug ═══")
	for id_val: int in _cache.keys():
		var data: AbilityData = _cache[id_val] as AbilityData
		print("  [%d] %s" % [id_val, data.name_key])
	print("═══════════════════════")
