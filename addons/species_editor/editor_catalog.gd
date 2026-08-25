@tool
extends RefCounted

class_name SpeciesEditorCatalog

const ABILITIES_PATH := "res://data_core/ability/resources/"
const MOVES_PATH := "res://data_core/move/resources/"

var abilities: Array[AbilityData] = []
var moves: Array[MoveData] = []
var errors: Array[String] = []
var loaded := false

func load_all() -> void:
	if loaded:
		return

	errors.clear()
	abilities.clear()
	moves.clear()
	_scan_abilities(ABILITIES_PATH)
	_scan_moves(MOVES_PATH)

	abilities.sort_custom(func(a: AbilityData, b: AbilityData) -> bool:
		return int(a.id) < int(b.id)
	)
	moves.sort_custom(func(a: MoveData, b: MoveData) -> bool:
		return int(a.move_id) < int(b.move_id)
	)
	loaded = true

func reload() -> void:
	loaded = false
	load_all()

func _scan_abilities(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		errors.append("No se pudo abrir: %s" % path)
		return

	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = path.path_join(entry)
			if directory.current_is_dir():
				_scan_abilities(full_path)
			elif entry.ends_with(".tres"):
				var resource := ResourceLoader.load(full_path)
				if resource is AbilityData:
					abilities.append(resource as AbilityData)
		entry = directory.get_next()

	directory.list_dir_end()

func _scan_moves(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		errors.append("No se pudo abrir: %s" % path)
		return

	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = path.path_join(entry)
			if directory.current_is_dir():
				_scan_moves(full_path)
			elif entry.ends_with(".tres"):
				var resource := ResourceLoader.load(full_path)
				if resource is MoveData:
					moves.append(resource as MoveData)
		entry = directory.get_next()

	directory.list_dir_end()
