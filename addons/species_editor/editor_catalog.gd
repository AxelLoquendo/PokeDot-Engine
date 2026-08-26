@tool
extends RefCounted

class_name SpeciesEditorCatalog

const ABILITIES_PATH: String = "res://data_core/ability/resources/"
const MOVES_PATH: String = "res://data_core/move/resources/"
const ITEMS_PATH: String = "res://data_core/items/resources/"

var abilities: Array[AbilityData] = []
var moves: Array[MoveData] = []
var items: Array[ItemData] = []
var errors: Array[String] = []
var loaded: bool = false

func load_all() -> void:
	if loaded:
		return
	errors.clear()
	abilities.clear()
	moves.clear()
	items.clear()
	_scan_abilities(ABILITIES_PATH)
	_scan_moves(MOVES_PATH)
	_scan_items(ITEMS_PATH)
	abilities.sort_custom(func(a: AbilityData, b: AbilityData) -> bool:
		return int(a.id) < int(b.id)
	)
	moves.sort_custom(func(a: MoveData, b: MoveData) -> bool:
		return int(a.move_id) < int(b.move_id)
	)
	items.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		return int(a.item_id) < int(b.item_id)
	)
	loaded = true

func reload() -> void:
	loaded = false
	load_all()

func _scan_abilities(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
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
				var resource: Resource = ResourceLoader.load(full_path)
				if resource is AbilityData:
					abilities.append(resource as AbilityData)
		entry = directory.get_next()
	directory.list_dir_end()

func _scan_moves(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
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
				var resource: Resource = ResourceLoader.load(full_path)
				if resource is MoveData:
					moves.append(resource as MoveData)
		entry = directory.get_next()
	directory.list_dir_end()

func _scan_items(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		errors.append("No se pudo abrir: %s" % path)
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = path.path_join(entry)
			if directory.current_is_dir():
				_scan_items(full_path)
			elif entry.ends_with(".tres"):
				var resource: Resource = ResourceLoader.load(full_path)
				if resource is ItemData:
					items.append(resource as ItemData)
		entry = directory.get_next()
	directory.list_dir_end()
