@tool
extends RefCounted

class_name SpeciesRepository

const SPECIES_PATH := "res://data_core/pokemon/resources/"
const FILE_EXTENSION := ".tres"

var _cache: Array[PokemonDataStruct] = []
var _paths: Dictionary = {}
var _errors: Array[String] = []

func load_all_species() -> Array[PokemonDataStruct]:
	_cache.clear()
	_paths.clear()
	_errors.clear()

	_scan_directory(SPECIES_PATH)
	_cache.sort_custom(func(a: PokemonDataStruct, b: PokemonDataStruct) -> bool:
		return int(a.species_id) < int(b.species_id)
	)

	return _cache.duplicate()

func get_species_path(species_id: Species.SpeciesID) -> String:
	return str(_paths.get(int(species_id), ""))

func get_errors() -> Array[String]:
	return _errors.duplicate()

func _scan_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		_errors.append("No se pudo abrir: %s" % path)
		return

	directory.list_dir_begin()
	var entry: String = directory.get_next()

	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = path.path_join(entry)

			if directory.current_is_dir():
				_scan_directory(full_path)
			elif entry.ends_with(FILE_EXTENSION):
				_load_species_file(full_path)

		entry = directory.get_next()

	directory.list_dir_end()

func _load_species_file(file_path: String) -> void:
	var resource := ResourceLoader.load(
		file_path,
		"",
		ResourceLoader.CACHE_MODE_IGNORE
	)

	if resource == null:
		_errors.append("No se pudo cargar: %s" % file_path)
		return

	if not resource is PokemonDataStruct:
		_errors.append("No es PokemonDataStruct: %s" % file_path)
		return

	var species := resource as PokemonDataStruct
	var id: int = int(species.species_id)

	if id == int(Species.SpeciesID.SPECIES_NONE):
		_errors.append("SPECIES_NONE en: %s" % file_path)
		return

	if _paths.has(id):
		_errors.append(
			"ID duplicado %d: %s y %s"
			% [id, str(_paths[id]), file_path]
		)
		return

	_cache.append(species)
	_paths[id] = file_path
