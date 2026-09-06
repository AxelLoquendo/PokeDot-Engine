extends Node
class_name MoveDB

const MOVE_PATH: String = "res://data_core/move/resources/"
const FILE_EXTENSION: String = ".tres"
const INDEX_SCRIPT = preload("res://data_core/generated/resource_index.gd")

var _cache: Dictionary = {}
var _paths: Dictionary = {}
var _loaded: bool = false
var _errors: Array[String] = []
var _warnings: Array[String] = []

signal database_loaded(count: int)

func _ready() -> void:
	load_database()

func get_move(move_id: Moves.MoveId) -> MoveData:
	if not _loaded:
		push_error("MoveDB: La base de datos no se ha cargado aún.")
		return null
	var id: int = int(move_id)
	if _cache.has(id):
		return _cache[id] as MoveData
	if _paths.has(id):
		_load_move_file(str(_paths[id]))
	return _cache.get(id) as MoveData

func has_move(move_id: Moves.MoveId) -> bool:
	if not _loaded:
		return false
	var id: int = int(move_id)
	return _cache.has(id) or _paths.has(id)

func get_all_moves() -> Array[MoveData]:
	_ensure_all_loaded()
	var result: Array[MoveData] = []
	for data: MoveData in _cache.values():
		result.append(data)
	return result

func get_move_count() -> int:
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
	var index: Dictionary = INDEX_SCRIPT.new().get_paths("moves")
	if index.is_empty():
		_load_from_subfolder(MOVE_PATH)
	else:
		_paths = index.duplicate()
	_loaded = true
	database_loaded.emit(get_move_count())
	print("MoveDB: índice listo con %d movimientos; cargados ahora: %d." % [get_move_count(), _cache.size()])

func _ensure_all_loaded() -> void:
	for id: int in _paths.keys():
		if not _cache.has(id):
			_load_move_file(str(_paths[id]))

func _load_from_subfolder(path: String) -> void:
	for entry: String in ResourceLoader.list_directory(path):
		if entry.begins_with("."):
			continue
		var full_path: String = path.path_join(entry)
		if entry.ends_with("/"):
			_load_from_subfolder(full_path)
		elif entry.ends_with(FILE_EXTENSION):
			_load_move_file(full_path)

func _load_move_file(path: String) -> void:
	var resource: Resource = load(path)
	if not resource is MoveData:
		_errors.append("'%s' no es un MoveData válido." % path)
		return
	var data: MoveData = resource as MoveData
	var id: int = int(data.move_id)
	if id == int(Moves.MoveId.MOVE_NONE):
		_errors.append("'%s' tiene ID = MOVE_NONE." % path)
		return
	if _cache.has(id):
		return
	var validation_errors: Array[String] = data._validate()
	if not validation_errors.is_empty():
		for error: String in validation_errors:
			_errors.append("'%s': %s" % [path.get_file(), error])
		return
	_cache[id] = data
