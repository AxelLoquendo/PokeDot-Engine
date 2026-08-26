@tool
extends RefCounted

## Repository for editor operations. Runtime ItemDB remains the source of truth
## for gameplay; this class only reads and writes ItemData resources.
class_name ItemEditorRepository

const ITEMS_PATH: String = "res://data_core/items/resources/"
const CUSTOM_PATH: String = "res://data_core/items/resources/custom/"
const TRASH_PATH: String = "res://data_core/items/trash/"
const FILE_EXTENSION: String = ".tres"

var records: Array[Dictionary] = []
var errors: Array[String] = []

func load_all() -> Array[Dictionary]:
	records.clear()
	errors.clear()
	_scan_directory(ITEMS_PATH)
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int((a.get("item") as ItemData).item_id) < int((b.get("item") as ItemData).item_id)
	)
	return records.duplicate()

func get_errors() -> Array[String]:
	return errors.duplicate()

func get_item_path(item_id: Items.ItemId) -> String:
	for record: Dictionary in records:
		var item: ItemData = record.get("item") as ItemData
		if item != null and int(item.item_id) == int(item_id):
			return str(record.get("path", ""))
	return ""

func get_item_at(path: String, force_reload: bool = true) -> ItemData:
	var resource: Resource
	if force_reload:
		resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		resource = load(path)
	return (resource as ItemData) if resource is ItemData else null

func id_is_used(value: int, except_path: String = "") -> bool:
	for record: Dictionary in records:
		if str(record.get("path", "")) == except_path:
			continue
		var item: ItemData = record.get("item") as ItemData
		if item != null and int(item.item_id) == value:
			return true
	return false

func next_available_id() -> int:
	for value: int in _enum_ids():
		if value > 0 and not id_is_used(value):
			return value
	return -1

func save_item(item: ItemData, path: String) -> Error:
	if item == null or path.is_empty():
		return ERR_INVALID_PARAMETER
	return ResourceSaver.save(item, path)

func make_directory(path: String) -> Error:
	return DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

func move_to_trash(path: String) -> String:
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	var directory_error: Error = make_directory(TRASH_PATH)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return ""
	var destination: String = TRASH_PATH.path_join(
		"%d_%s" % [Time.get_unix_time_from_system(), path.get_file()]
	)
	var move_error: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(destination)
	)
	return destination if move_error == OK else ""

func list_trash() -> Array[String]:
	var result: Array[String] = []
	_scan_trash(TRASH_PATH, result)
	result.sort()
	return result

func restore_from_trash(trash_path: String) -> String:
	if trash_path.is_empty() or not FileAccess.file_exists(trash_path):
		return ""
	var file_name: String = trash_path.get_file()
	var separator: int = file_name.find("_")
	if separator < 0 or separator == file_name.length() - 1:
		return ""
	var original_name: String = file_name.substr(separator + 1)
	var destination: String = CUSTOM_PATH.path_join(original_name)
	if FileAccess.file_exists(destination):
		return ""
	var directory_error: Error = make_directory(CUSTOM_PATH)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return ""
	var move_error: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(trash_path), ProjectSettings.globalize_path(destination)
	)
	return destination if move_error == OK else ""

func _enum_ids() -> Array[int]:
	var values: Array[int] = []
	for value: int in Items.ItemId.values():
		if not values.has(value):
			values.append(value)
	values.sort()
	return values

func _scan_directory(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = path.path_join(entry)
			if directory.current_is_dir():
				_scan_directory(full_path)
			elif entry.ends_with(FILE_EXTENSION):
				_load_record(full_path)
		entry = directory.get_next()
	directory.list_dir_end()

func _load_record(path: String) -> void:
	var item: ItemData = get_item_at(path)
	if item == null:
		errors.append("No es un ItemData válido: %s" % path)
		return
	for record: Dictionary in records:
		var previous: ItemData = record.get("item") as ItemData
		if previous != null and int(previous.item_id) == int(item.item_id):
			errors.append("ID duplicado %d: %s y %s" % [int(item.item_id), record["path"], path])
			return
	records.append({"item": item, "path": path})

func _scan_trash(path: String, result: Array[String]) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		var full_path: String = path.path_join(entry)
		if not entry.begins_with("."):
			if directory.current_is_dir():
				_scan_trash(full_path, result)
			elif entry.ends_with(FILE_EXTENSION):
				result.append(full_path)
		entry = directory.get_next()
	directory.list_dir_end()
