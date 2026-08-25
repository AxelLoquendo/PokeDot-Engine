@tool
extends Node

class_name SpeciesDB

const SPECIES_PATH: String = "res://data_core/pokemon/resources/"
const FILE_EXTENSION: String = ".tres"

var _cache: Dictionary = {}
var _loaded: bool = false
var _loading: bool = false

var _errors: Array[String] = []
var _warnings: Array[String] = []

signal database_loaded(count: int)
signal database_error(message: String)

func _ready() -> void:
	load_database()

func get_species(species_id: Species.SpeciesID) -> PokemonDataStruct:
	if not _loaded:
		push_error("SpeciesDB: La base de datos no se ha cargado aún.")
		return null

	var key: int = int(species_id)
	if _cache.has(key):
		return _cache[key] as PokemonDataStruct

	push_warning("SpeciesDB: Especie %d no encontrada." % key)
	return null

func has_species(species_id: Species.SpeciesID) -> bool:
	return _loaded and _cache.has(int(species_id))

func get_all_species() -> Array[PokemonDataStruct]:
	var result: Array[PokemonDataStruct] = []
	for value: Variant in _cache.values():
		var data: PokemonDataStruct = value as PokemonDataStruct
		if data != null:
			result.append(data)
	return result

func get_species_count() -> int:
	return _cache.size()

func get_load_errors() -> Array[String]:
	return _errors.duplicate()

func get_load_warnings() -> Array[String]:
	return _warnings.duplicate()

func reload_database() -> void:
	load_database()

## Siempre comienza desde cero. Esto evita falsos duplicados si load_database()
## se llama más de una vez por el autoload, una escena o una recarga de scripts.
func load_database() -> void:
	if _loading:
		return

	_loading = true
	_loaded = false
	_cache.clear()
	_errors.clear()
	_warnings.clear()

	var directory: DirAccess = DirAccess.open(SPECIES_PATH)
	if directory == null:
		var message: String = "SpeciesDB: No se pudo abrir '%s'." % SPECIES_PATH
		_errors.append(message)
		database_error.emit(message)
		push_error(message)
		_loading = false
		return

	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = SPECIES_PATH.path_join(entry)
			if directory.current_is_dir():
				_load_from_subfolder(full_path)
			elif entry.ends_with(FILE_EXTENSION):
				_load_species_file(full_path)
		entry = directory.get_next()
	directory.list_dir_end()

	_loaded = true
	_loading = false
	database_loaded.emit(_cache.size())
	print("SpeciesDB: %d especies cargadas." % _cache.size())

	if not _errors.is_empty():
		print("SpeciesDB: %d errores:" % _errors.size())
		for message: String in _errors:
			push_error("  ✖ %s" % message)

func _load_from_subfolder(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		_errors.append("No se pudo abrir la carpeta '%s'." % path)
		return

	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = path.path_join(entry)
			if directory.current_is_dir():
				_load_from_subfolder(full_path)
			elif entry.ends_with(FILE_EXTENSION):
				_load_species_file(full_path)
		entry = directory.get_next()
	directory.list_dir_end()

func _load_species_file(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)
	if resource == null:
		_errors.append("'%s' no se pudo cargar." % path)
		return

	if not resource is PokemonDataStruct:
		_errors.append("'%s' no es un PokemonDataStruct válido." % path)
		return

	var data: PokemonDataStruct = resource as PokemonDataStruct
	var id: int = int(data.species_id)
	if id == int(Species.SpeciesID.SPECIES_NONE):
		_errors.append("'%s' tiene SPECIES_NONE." % path)
		return

	var validation_errors: Array[String] = data._validate()
	for validation_error: String in validation_errors:
		_errors.append("'%s': %s" % [path, validation_error])
	if not validation_errors.is_empty():
		return

	if _cache.has(id):
		var existing: PokemonDataStruct = _cache[id] as PokemonDataStruct
		_errors.append(
			"ID %d duplicado: '%s' vs '%s'." %
			[id, existing.resource_path, path]
		)
		return

	_cache[id] = data
