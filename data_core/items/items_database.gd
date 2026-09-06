extends Node
class_name ItemDB

const ITEMS_PATH: String = "res://data_core/items/resources/"
const FILE_EXTENSION: String = ".tres"
const INDEX_SCRIPT = preload("res://data_core/generated/resource_index.gd")

var _cache: Dictionary = {}
var _paths: Dictionary = {}
var _loaded: bool = false
var _errors: Array[String] = []
var _warnings: Array[String] = []

signal database_loaded(count: int)
signal database_error(message: String)

func _ready() -> void:
	load_database()

func get_item(item_id: Items.ItemId) -> ItemData:
	if not _loaded:
		return null
	var id: int = int(item_id)
	if _cache.has(id):
		return _cache[id] as ItemData
	if _paths.has(id):
		_load_item_file(str(_paths[id]))
	return _cache.get(id) as ItemData

func has_item(item_id: Items.ItemId) -> bool:
	if not _loaded:
		return false
	var id: int = int(item_id)
	return _cache.has(id) or _paths.has(id)

func get_all_items() -> Array[ItemData]:
	_ensure_all_loaded()
	var result: Array[ItemData] = []
	for data: ItemData in _cache.values():
		result.append(data)
	return result

func get_item_count() -> int:
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
	var index: Dictionary = INDEX_SCRIPT.new().get_paths("items")
	if index.is_empty():
		if not DirAccess.dir_exists_absolute(ITEMS_PATH):
			_loaded = true
			database_error.emit("ItemDB: no existe '%s'." % ITEMS_PATH)
			database_loaded.emit(0)
			return
		_load_folder(ITEMS_PATH)
	else:
		_paths = index.duplicate()
	_loaded = true
	database_loaded.emit(get_item_count())
	print("ItemDB: índice listo con %d ítems; cargados ahora: %d." % [get_item_count(), _cache.size()])
	for error: String in _errors:
		push_error(error)

func _ensure_all_loaded() -> void:
	for id: int in _paths.keys():
		if not _cache.has(id):
			_load_item_file(str(_paths[id]))

func _load_folder(path: String) -> void:
	for entry: String in ResourceLoader.list_directory(path):
		if entry.begins_with("."):
			continue
		var full_path: String = path.path_join(entry)
		if entry.ends_with("/"):
			_load_folder(full_path)
		elif entry.ends_with(FILE_EXTENSION):
			_load_item_file(full_path)

func _load_item_file(path: String) -> void:
	var resource: Resource = load(path)
	if not resource is ItemData:
		_errors.append("'%s' no es un ItemData válido." % path)
		return
	var item: ItemData = resource as ItemData
	var id: int = int(item.item_id)
	if _cache.has(id):
		return
	var validation_errors: Array[String] = item._validate()
	if not validation_errors.is_empty():
		for error: String in validation_errors:
			_errors.append("'%s': %s" % [path, error])
		return
	_cache[id] = item
