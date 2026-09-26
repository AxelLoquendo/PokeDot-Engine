extends RefCounted
class_name TrainerDatabase

## Entrenadores de los .txt de TRAINERS_DIR. Se cargan la primera vez.

const TRAINERS_DIR: String = "res://game/trainers/"

static var _trainers: Dictionary = {}
static var _loaded: bool = false
static var _errors: Array[String] = []
static var _warnings: Array[String] = []


static func get_trainer(trainer_id: String) -> TrainerData:
	_ensure_loaded()
	return _trainers.get(trainer_id.strip_edges().to_upper()) as TrainerData


static func has_trainer(trainer_id: String) -> bool:
	_ensure_loaded()
	return _trainers.has(trainer_id.strip_edges().to_upper())


static func get_trainer_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for trainer_id: String in _trainers.keys():
		ids.append(trainer_id)
	ids.sort()
	return ids


## "archivo:línea: mensaje"
static func get_errors() -> Array[String]:
	_ensure_loaded()
	return _errors.duplicate()


static func get_warnings() -> Array[String]:
	_ensure_loaded()
	return _warnings.duplicate()


static func reload() -> void:
	_trainers.clear()
	_errors.clear()
	_warnings.clear()
	_loaded = true
	for path: String in _find_files(TRAINERS_DIR):
		var parser: TrainerPartyParser = TrainerPartyParser.new()
		parser.parse_file(path)
		_errors.append_array(parser.errors)
		_warnings.append_array(parser.warnings)
		for trainer: TrainerData in parser.trainers:
			if _trainers.has(trainer.trainer_id):
				var first: TrainerData = _trainers[trainer.trainer_id]
				_errors.append("%s:%d: %s ya está definido en %s:%d." % [
					trainer.source_path, trainer.source_line, trainer.trainer_id,
					first.source_path, first.source_line
				])
				continue
			_trainers[trainer.trainer_id] = trainer
	for message: String in _errors:
		push_error("Entrenadores: %s" % message)


static func _ensure_loaded() -> void:
	if not _loaded:
		reload()


static func _find_files(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return found
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		var full_path: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				found.append_array(_find_files(full_path))
		elif entry.get_extension() == "txt":
			found.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()
	found.sort()
	return found
