extends Node
class_name MoveDB

const MOVE_PATH: String = "res://data_core/move/resources/"
const FILE_EXTENSION: String = ".tres"

var _cache: Dictionary = {}
var _loaded: bool = false
var _errors: Array[String] = []
var _warnings: Array[String] = []

signal database_loaded(count: int)
#signal database_error(message: String)


func _ready() -> void:
	load_database()


func get_move(move_id: Moves.MoveId) -> MoveData:
	if not _loaded:
		push_error("MoveDB: La base de datos no se ha cargado aún.")
		return null

	if _cache.has(move_id):
		return _cache[move_id] as MoveData

	push_warning("MoveDB: Movimiento %d no encontrado." % move_id)
	return null


func has_move(move_id: Moves.MoveId) -> bool:
	if not _loaded:
		return false

	return _cache.has(move_id)


func get_all_moves() -> Array[MoveData]:
	var result: Array[MoveData] = []

	for data: MoveData in _cache.values():
		result.append(data)

	return result


func get_move_count() -> int:
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
	_load_from_subfolder(MOVE_PATH)

	_loaded = true
	database_loaded.emit(_cache.size())

	print("MoveDB: %d movimientos cargados." % _cache.size())

	if not _errors.is_empty():
		print("MoveDB: %d errores:" % _errors.size())
		for error: String in _errors:
			push_error("  ✖ %s" % error)


func _load_from_subfolder(path: String) -> void:
	for entry: String in ResourceLoader.list_directory(path):
		var full_path: String = path.path_join(entry)
		if entry.ends_with("/"):
			_load_from_subfolder(full_path)
		elif entry.ends_with(FILE_EXTENSION):
			_load_move_file(full_path)

func _load_move_file(path: String) -> void:
	var recurso_cargado: Resource = load(path)

	if not recurso_cargado is MoveData:
		_errors.append(
			"'%s' no es un MoveData válido." % path
		)
		return

	var data: MoveData = recurso_cargado as MoveData

	if data.move_id == Moves.MoveId.MOVE_NONE:
		_errors.append(
			"'%s' tiene ID = MOVE_NONE." % path
		)
		return

	var validation_errors: Array[String] = data._validate()

	if not validation_errors.is_empty():
		for error: String in validation_errors:
			_errors.append(
				"'%s': %s" % [path, error]
			)

		return

	if _cache.has(data.move_id):
		var existing: MoveData = _cache[data.move_id] as MoveData

		_errors.append(
			"ID %d duplicado: '%s' vs '%s'"
			% [
				data.move_id,
				existing.resource_path,
				path
			]
		)

		return

	_cache[data.move_id] = data
