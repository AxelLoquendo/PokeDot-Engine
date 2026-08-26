@tool
extends RefCounted

## Lightweight editor catalog.  It deliberately scans resources instead of
## instantiating ItemDB, so editing does not change the runtime database.
class_name ItemEditorCatalog

const ITEMS_PATH: String = "res://data_core/items/resources/"
const FILE_EXTENSION: String = ".tres"

var items: Array[ItemData] = []
var paths_by_id: Dictionary = {}
var errors: Array[String] = []
var loaded: bool = false

func load_all() -> void:
	if loaded:
		return
	_reload_contents()
	loaded = true

func reload() -> void:
	loaded = false
	_reload_contents()
	loaded = true

func _reload_contents() -> void:
	items.clear()
	paths_by_id.clear()
	errors.clear()
	_scan_directory(ITEMS_PATH)
	items.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		return int(a.item_id) < int(b.item_id)
	)

func get_errors() -> Array[String]:
	return errors.duplicate()

func get_path(item_id: Items.ItemId) -> String:
	return str(paths_by_id.get(int(item_id), ""))

func enum_ids() -> Array[int]:
	var result: Array[int] = []
	for value: int in Items.ItemId.values():
		if not result.has(value):
			result.append(value)
	result.sort()
	return result

func _scan_directory(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		# An absent data directory is normal in a fresh project.  Do not report it
		# as a hard load error because the create action can make it later.
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = path.path_join(entry)
			if directory.current_is_dir():
				_scan_directory(full_path)
			elif entry.ends_with(FILE_EXTENSION):
				_load_item(full_path)
		entry = directory.get_next()
	directory.list_dir_end()

func _load_item(path: String) -> void:
	var resource: Resource = ResourceLoader.load(
		path, "", ResourceLoader.CACHE_MODE_IGNORE
	)
	if resource == null:
		errors.append("No se pudo cargar: %s" % path)
		return
	if not resource is ItemData:
		errors.append("No es ItemData: %s" % path)
		return
	var item: ItemData = resource as ItemData
	var id: int = int(item.item_id)
	if paths_by_id.has(id):
		errors.append("ID duplicado %d: %s y %s" % [id, paths_by_id[id], path])
		return
	items.append(item)
	paths_by_id[id] = path
