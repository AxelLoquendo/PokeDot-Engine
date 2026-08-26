@tool
extends RefCounted

## File-system repository for MoveData resources.
## The editor deliberately does not use MoveDB: MoveDB is a runtime Node and
## ignores files at the root of MOVE_PATH, while an editor needs full paths.
class_name MoveEditorRepository

const MOVE_PATH: String = "res://data_core/move/resources/"
const FILE_EXTENSION: String = ".tres"

var _entries: Array[Dictionary] = []
var _paths_by_id: Dictionary = {}
var _errors: Array[String] = []

func load_all() -> Array[Dictionary]:
	_entries.clear()
	_paths_by_id.clear()
	_errors.clear()
	_scan_directory(MOVE_PATH)
	_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id: int = int(a.get("id", 0))
		var b_id: int = int(b.get("id", 0))
		if a_id == b_id:
			return str(a.get("path", "")) < str(b.get("path", ""))
		return a_id < b_id
	)
	return _entries.duplicate()

func get_errors() -> Array[String]:
	return _errors.duplicate()

func get_path(move_id: Moves.MoveId) -> String:
	return str(_paths_by_id.get(int(move_id), ""))

func get_entry(path: String) -> Dictionary:
	for entry: Dictionary in _entries:
		if str(entry.get("path", "")) == path:
			return entry
	return {}

func list_trash(trash_path: String) -> Array[String]:
	var result: Array[String] = []
	var directory: DirAccess = DirAccess.open(trash_path)
	if directory == null:
		return result
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with(".") and not directory.current_is_dir() and entry.ends_with(FILE_EXTENSION):
			result.append(trash_path.path_join(entry))
		entry = directory.get_next()
	directory.list_dir_end()
	result.sort()
	return result

func _scan_directory(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		# A missing resources directory is normal in a fresh project. Keep the
		# message useful, but do not make the dock unusable.
		if path == MOVE_PATH:
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
				_load_file(full_path)
		entry = directory.get_next()
	directory.list_dir_end()

func _load_file(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		_errors.append("No se pudo cargar: %s" % path)
		return
	if not resource is MoveData:
		_errors.append("No es MoveData: %s" % path)
		return
	var data: MoveData = resource as MoveData
	var id: int = int(data.move_id)
	if id == int(Moves.MoveId.MOVE_NONE):
		_errors.append("MOVE_NONE ignorado: %s" % path)
		return
	if _paths_by_id.has(id):
		_errors.append("ID %d duplicado: %s y %s" % [id, str(_paths_by_id[id]), path])
		return
	_paths_by_id[id] = path
	_entries.append({
		"id": id,
		"name": data.move_name,
		"path": path,
		"data": data,
		"valid": data._validate().is_empty(),
	})
