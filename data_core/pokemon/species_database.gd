extends Node
class_name SpeciesDB

const SPECIES_PATH: String = "res://data_core/pokemon/resources/"
const FILE_EXTENSION: String = ".tres"

var _cache: Dictionary = {}
var _loaded: bool = false

var _errors: Array[String] = []
var _warnings: Array[String] = []

signal database_loaded(count: int)
signal database_error(message: String)


func _ready() -> void:
	load_database()


func get_species(species_id: Species.SpeciesID) -> PokemonDataStruct:
	if not _loaded:
		push_error(
			"SpeciesDB: La base de datos no se ha cargado aún."
		)
		return null

	if _cache.has(species_id):
		return _cache[species_id] as PokemonDataStruct

	push_warning(
		"SpeciesDB: Especie %d no encontrada."
		% species_id
	)

	return null


func has_species(species_id: Species.SpeciesID) -> bool:
	if not _loaded:
		return false

	return _cache.has(species_id)


func get_all_species() -> Array[PokemonDataStruct]:
	var result: Array[PokemonDataStruct] = []

	for data: PokemonDataStruct in _cache.values():
		result.append(data)

	return result


func get_species_count() -> int:
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


func load_database() -> void:

	var dir: DirAccess = DirAccess.open(SPECIES_PATH)

	if dir == null:

		var msg: String = (
			"SpeciesDB: No se pudo abrir '%s'."
			% SPECIES_PATH
		)

		_errors.append(msg)
		database_error.emit(msg)
		push_error(msg)

		return


	dir.list_dir_begin()

	var entry: String = dir.get_next()

	while entry != "":

		if dir.current_is_dir():
			_load_from_subfolder(
				SPECIES_PATH.path_join(entry)
			)

		entry = dir.get_next()

	dir.list_dir_end()

	_loaded = true

	database_loaded.emit(_cache.size())

	print(
		"SpeciesDB: %d especies cargadas."
		% _cache.size()
	)


	if not _errors.is_empty():

		print(
			"SpeciesDB: %d errores:"
			% _errors.size()
		)

		for error: String in _errors:
			push_error(
				"  ✖ %s"
				% error
			)


func _load_from_subfolder(path: String) -> void:

	var dir: DirAccess = DirAccess.open(path)

	if dir == null:
		return

	dir.list_dir_begin()

	var file_name: String = dir.get_next()

	while file_name != "":

		if dir.current_is_dir():

			_load_from_subfolder(
				path.path_join(file_name)
			)

		elif file_name.ends_with(FILE_EXTENSION):

			_load_species_file(
				path.path_join(file_name)
			)

		file_name = dir.get_next()

	dir.list_dir_end()


func _load_species_file(path: String) -> void:

	var resource: Resource = load(path)


	if resource == null:

		_errors.append(
			"'%s' no se pudo cargar."
			% path
		)

		return


	if not resource is PokemonDataStruct:

		_errors.append(
			"'%s' no es un PokemonDataStruct válido."
			% path
		)

		return


	var data: PokemonDataStruct = (
		resource as PokemonDataStruct
	)


	# ─────────────────────────────
	# ID
	# ─────────────────────────────

	if data.species_id == Species.SpeciesID.SPECIES_NONE:

		_errors.append(
			"'%s' tiene SPECIES_NONE."
			% path
		)

		return


	# ─────────────────────────────
	# Validación interna
	# ─────────────────────────────

	var validation_errors: Array[String] = (
		data._validate()
	)


	if not validation_errors.is_empty():

		for error: String in validation_errors:

			_errors.append(
				"'%s': %s"
				% [path, error]
			)

		return


	# ─────────────────────────────
	# ID duplicado
	# ─────────────────────────────

	if _cache.has(data.species_id):

		var existing: PokemonDataStruct = (
			_cache[data.species_id]
			as PokemonDataStruct
		)

		_errors.append(
			"ID %d duplicado: '%s' vs '%s'."
			% [
				data.species_id,
				existing.resource_path,
				path
			]
		)

		return


	_cache[data.species_id] = data
