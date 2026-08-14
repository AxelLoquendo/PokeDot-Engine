extends Node
class_name ItemDB

## Base de datos de ItemData. Coloca recursos .tres en data_core/items/resources/
const ITEMS_PATH: String = "res://data_core/items/resources/"
const FILE_EXTENSION: String = ".tres"

var _cache: Dictionary = {}
var _loaded: bool = false
var _errors: Array[String] = []
var _warnings: Array[String] = []

signal database_loaded(count: int)
signal database_error(message: String)


func _ready() -> void:
	load_database()


func get_item(item_id: Items.ItemId) -> ItemData:
	return _cache.get(item_id, null) as ItemData


func has_item(item_id: Items.ItemId) -> bool:
	return _cache.has(item_id)


func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item: ItemData in _cache.values():
		result.append(item)
	return result


func get_load_errors() -> Array[String]:
	return _errors.duplicate()


func get_load_warnings() -> Array[String]:
	return _warnings.duplicate()


func reload_database() -> void:
	_cache.clear()
	_errors.clear()
	_warnings.clear()
	_loaded = false
	load_database()


func load_database() -> void:
	var directory: DirAccess = DirAccess.open(ITEMS_PATH)
	if directory == null:
		var message: String = "ItemDB: no existe '%s'; aún no hay ItemData que cargar." % ITEMS_PATH
		_warnings.append(message)
		database_error.emit(message)
		_loaded = true
		database_loaded.emit(0)
		return
	_load_folder(ITEMS_PATH)
	_loaded = true
	database_loaded.emit(_cache.size())
	for error: String in _errors:
		push_error(error)


func _load_folder(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		var full_path: String = path.path_join(entry)
		if directory.current_is_dir():
			_load_folder(full_path)
		elif entry.ends_with(FILE_EXTENSION):
			_load_item_file(full_path)
		entry = directory.get_next()
	directory.list_dir_end()


func _load_item_file(path: String) -> void:
	var resource: Resource = load(path)
	if not resource is ItemData:
		_errors.append("'%s' no es un ItemData válido." % path)
		return
	var item: ItemData = resource as ItemData
	var validation_errors: Array[String] = item._validate()
	for error: String in validation_errors:
		_errors.append("'%s': %s" % [path, error])
	if not validation_errors.is_empty():
		return
	if _cache.has(item.item_id):
		_errors.append("ID de ítem duplicado %d: '%s' y '%s'." % [item.item_id, (_cache[item.item_id] as ItemData).resource_path, path])
		return
	_cache[item.item_id] = item
