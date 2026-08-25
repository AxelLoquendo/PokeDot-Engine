extends RefCounted

class_name SpeciesRepository

const SPECIES_PATH: String = "res://data_core/pokemon/resources/"
const FILE_EXTENSION: String = ".tres"

var _cache: Array[PokemonDataStruct] = []
var _errors: Array[String] = []

func load_all_species() -> Array[PokemonDataStruct]:
	_cache.clear()
	_errors.clear()

	var dir = DirAccess.open(SPECIES_PATH)
	if dir == null:
		_errors.append("Could not open directory: %s" % SPECIES_PATH)
		push_error(_errors[-1])
		return _cache

	_scan_directory(SPECIES_PATH, dir)
	_sort_by_id()

	if not _errors.is_empty():
		push_warning("SpeciesRepository: %d errors during load" % _errors.size())
		for error in _errors:
			push_error("  ✗ %s" % error)

	print("SpeciesRepository: Loaded %d species" % _cache.size())
	return _cache

func _scan_directory(path: String, dir: DirAccess) -> void:
	dir.list_dir_begin()
	var entry = dir.get_next()

	while entry != "":
		if dir.current_is_dir():
			var subdir = DirAccess.open(path.path_join(entry))
			if subdir:
				_scan_directory(path.path_join(entry), subdir)
		elif entry.ends_with(FILE_EXTENSION):
			_load_species_file(path.path_join(entry))

		entry = dir.get_next()

func _load_species_file(file_path: String) -> void:
	var resource = load(file_path)

	if resource == null:
		_errors.append("Failed to load: %s" % file_path)
		return

	if not resource is PokemonDataStruct:
		_errors.append("Invalid resource type: %s" % file_path)
		return

	var species = resource as PokemonDataStruct
	if species.species_id == Species.SpeciesID.SPECIES_NONE:
		_errors.append("Missing species_id: %s" % file_path)
		return

	_cache.append(species)

func _sort_by_id() -> void:
	_cache.sort_custom(func(a, b): return int(a.species_id) < int(b.species_id))

func get_errors() -> Array[String]:
	return _errors
