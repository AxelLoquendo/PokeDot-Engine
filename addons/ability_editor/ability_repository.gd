@tool
extends RefCounted
class_name AbilityEditorRepository

## Filesystem-backed repository for AbilityData resources.
##
## This class deliberately has no UI dependencies, so it can also be reused by
## importers, migration tools, tests, or another editor. All paths are project
## paths (res://), not OS paths.

const ABILITIES_PATH := "res://data_core/ability/resources/"
const CUSTOM_PATH := "res://data_core/ability/resources/custom/"
const TRASH_PATH := "res://data_core/ability/trash/"
const FILE_EXTENSION := ".tres"

var _records: Array[Dictionary] = []
var _errors: Array[String] = []
var _loaded := false

func load_all() -> Array[Dictionary]:
	_records.clear()
	_errors.clear()
	_scan_directory(ABILITIES_PATH, false)
	_scan_directory(TRASH_PATH, true)
	_records.sort_custom(_sort_records)
	_loaded = true
	return get_records()

func reload() -> Array[Dictionary]:
	_loaded = false
	return load_all()

func is_loaded() -> bool:
	return _loaded

func get_records(include_trash := true) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for record: Dictionary in _records:
		if include_trash or not bool(record.get("trashed", false)):
			result.append(record.duplicate(true))
	return result

func get_live_records() -> Array[Dictionary]:
	return get_records(false)

func get_errors() -> Array[String]:
	return _errors.duplicate()

func _ensure_loaded() -> void:
	if not _loaded:
		load_all()

func get_record_by_path(path: String) -> Dictionary:
	_ensure_loaded()
	for record: Dictionary in _records:
		if str(record.get("path", "")) == path:
			return record
	return {}

func get_live_record_by_id(id_value: int) -> Dictionary:
	_ensure_loaded()
	for record: Dictionary in _records:
		if not bool(record.get("trashed", false)) and int(record.get("id", -1)) == id_value:
			return record
	return {}

func _max_enum_id() -> int:
	return int(AbilityId.Id.COUNT) - 1

func get_next_id() -> int:
	_ensure_loaded()
	var used := {}
	for record: Dictionary in _records:
		if not bool(record.get("trashed", false)):
			used[int(record.get("id", -1))] = true
	for id_value: int in range(1, _max_enum_id() + 1):
		if not used.has(id_value):
			return id_value
	return -1

func create(data: AbilityData, file_stem := "") -> String:
	if data == null:
		_errors.append("No se puede crear un AbilityData nulo.")
		return ""
	if int(data.id) <= 0 or int(data.id) > _max_enum_id():
		_errors.append("El ID %d está fuera del rango de AbilityId.Id." % int(data.id))
		return ""
	if not get_live_record_by_id(int(data.id)).is_empty():
		_errors.append("El ID %d ya está en uso." % int(data.id))
		return ""
	var stem := _safe_stem(file_stem)
	if stem.is_empty():
		stem = "ability_%03d" % int(data.id)
	var path := CUSTOM_PATH.path_join(stem + FILE_EXTENSION)
	path = _unused_path(path)
	var error := _save_resource(data, path)
	if error != OK:
		return ""
	load_all()
	return path

func save(data: AbilityData, path: String) -> bool:
	if data == null or path.is_empty():
		_errors.append("Faltan datos o ruta para guardar la habilidad.")
		return false
	if bool(get_record_by_path(path).get("trashed", false)):
		_errors.append("No se puede guardar un recurso en la papelera.")
		return false
	var conflict := get_live_record_by_id(int(data.id))
	if not conflict.is_empty() and str(conflict.get("path", "")) != path:
		_errors.append("El ID %d ya pertenece a '%s'." % [int(data.id), str(conflict.get("path", ""))])
		return false
	return _save_resource(data, path) == OK

func duplicate(data: AbilityData, requested_id: int, file_stem := "") -> String:
	if data == null:
		_errors.append("Selecciona una habilidad antes de duplicar.")
		return ""
	if requested_id <= 0 or requested_id > _max_enum_id():
		_errors.append("El ID de la copia está fuera del rango válido.")
		return ""
	if not get_live_record_by_id(requested_id).is_empty():
		_errors.append("El ID %d ya está en uso." % requested_id)
		return ""
	var copy := data.duplicate(true) as AbilityData
	copy.id = requested_id as AbilityId.Id
	var stem := _safe_stem(file_stem)
	if stem.is_empty():
		stem = "ability_%03d" % requested_id
	var path := _unused_path(CUSTOM_PATH.path_join(stem + FILE_EXTENSION))
	if _save_resource(copy, path) != OK:
		return ""
	load_all()
	return path

func move_to_trash(path: String) -> bool:
	var record := get_record_by_path(path)
	if record.is_empty() or bool(record.get("trashed", false)):
		_errors.append("No se encontró un recurso activo en '%s'." % path)
		return false
	var destination := _unused_path(TRASH_PATH.path_join(path.get_file()))
	if not _ensure_directory(TRASH_PATH):
		return false
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path),
		ProjectSettings.globalize_path(destination)
	)
	if error != OK:
		_errors.append("No se pudo mover '%s' a la papelera (%s)." % [path, error_string(error)])
		return false
	load_all()
	return true

func restore(path: String) -> String:
	var record := get_record_by_path(path)
	if record.is_empty() or not bool(record.get("trashed", false)):
		_errors.append("No se encontró ese recurso en la papelera.")
		return ""
	var id_value := int(record.get("id", -1))
	if not get_live_record_by_id(id_value).is_empty():
		_errors.append("No se puede restaurar: el ID %d ya está en uso." % id_value)
		return ""
	var destination := _unused_path(CUSTOM_PATH.path_join(path.get_file()))
	if not _ensure_directory(CUSTOM_PATH):
		return ""
	var error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path),
		ProjectSettings.globalize_path(destination)
	)
	if error != OK:
		_errors.append("No se pudo restaurar '%s' (%s)." % [path, error_string(error)])
		return ""
	load_all()
	return destination

func _scan_directory(path: String, trashed: bool) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		# A missing trash folder is expected on a fresh checkout.
		if not trashed:
			_errors.append("No se pudo abrir: %s" % path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path := path.path_join(entry)
			if directory.current_is_dir():
				_scan_directory(full_path, trashed)
			elif entry.ends_with(FILE_EXTENSION):
				_load_file(full_path, trashed)
		entry = directory.get_next()
	directory.list_dir_end()

func _load_file(path: String, trashed: bool) -> void:
	var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		_errors.append("No se pudo cargar: %s" % path)
		return
	if not resource is AbilityData:
		_errors.append("No es AbilityData: %s" % path)
		return
	var data := resource as AbilityData
	var record := {
		"path": path,
		"data": data,
		"id": int(data.id),
		"trashed": trashed,
		"valid": data.is_valid(),
		"errors": data._validate(),
	}
	_records.append(record)

func _save_resource(data: AbilityData, path: String) -> Error:
	if not _ensure_directory(path.get_base_dir()):
		return ERR_CANT_CREATE
	var error := ResourceSaver.save(data, path)
	if error != OK:
		_errors.append("No se pudo guardar '%s': %s" % [path, error_string(error)])
	return error

func _ensure_directory(path: String) -> bool:
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	if error != OK and error != ERR_ALREADY_EXISTS:
		_errors.append("No se pudo crear la carpeta '%s': %s" % [path, error_string(error)])
		return false
	return true

func _unused_path(path: String) -> String:
	var candidate := path
	var index := 2
	while FileAccess.file_exists(candidate):
		candidate = path.get_base_dir().path_join(
			path.get_basename().get_file() + "_%d" % index + FILE_EXTENSION
		)
		index += 1
	return candidate

func _safe_stem(value: String) -> String:
	var result := value.strip_edges().to_lower()
	result = result.replace(" ", "_")
	var allowed := "abcdefghijklmnopqrstuvwxyz0123456789_-"
	var clean := ""
	for character: String in result:
		if allowed.contains(character):
			clean += character
	return clean.trim_prefix("_").trim_suffix("_")

func _sort_records(a: Dictionary, b: Dictionary) -> bool:
	var a_trash := bool(a.get("trashed", false))
	var b_trash := bool(b.get("trashed", false))
	if a_trash != b_trash:
		return not a_trash
	return int(a.get("id", -1)) < int(b.get("id", -1))
