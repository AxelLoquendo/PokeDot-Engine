@tool
extends Node

class_name SpeciesDB

const SPECIES_PATH: String = "res://data_core/pokemon/resources/"
const FILE_EXTENSION: String = ".tres"

## Especies base cargadas por su SpeciesID.
var _cache: Dictionary = {}
## Formas embebidas en una especie base, indexadas por su propio SpeciesID.
var _form_cache: Dictionary = {}
## Relación forma -> especie base.
var _form_base_cache: Dictionary = {}
## Vistas combinadas para acceder a una forma por su SpeciesID.
var _resolved_cache: Dictionary = {}
var _loaded: bool = false
var _loading: bool = false

var _errors: Array[String] = []
var _warnings: Array[String] = []

signal database_loaded(count: int)
#signal database_error(message: String)

func _ready() -> void:
	load_database()

## Devuelve los datos utilizables por el juego. Si species_id es el ID de
## una forma, devuelve una vista combinada de la base y sus sobrescrituras.
func get_species(species_id: Species.SpeciesID) -> PokemonDataStruct:
	if not _loaded:
		push_error("SpeciesDB: La base de datos no se ha cargado aún.")
		return null

	var key: int = int(species_id)
	if _cache.has(key):
		return _cache[key] as PokemonDataStruct
	if _resolved_cache.has(key):
		return _resolved_cache[key] as PokemonDataStruct
	if _form_base_cache.has(key):
		var resolved: PokemonDataStruct = _build_resolved_species(
			_form_base_cache[key] as PokemonDataStruct,
			_form_cache[key] as PokemonFormData
		)
		_resolved_cache[key] = resolved
		return resolved

	push_warning("SpeciesDB: Especie o forma %d no encontrada." % key)
	return null

## Devuelve siempre el recurso base, incluso cuando el ID recibido es el de
## una forma. Es útil para el resolver y para operaciones de herencia.
func get_base_species(species_id: Species.SpeciesID) -> PokemonDataStruct:
	var key: int = int(species_id)
	if _cache.has(key):
		return _cache[key] as PokemonDataStruct
	return _form_base_cache.get(key) as PokemonDataStruct

## Devuelve directamente la forma cuyo ID está declarado en species.gd.
func get_form(form_species_id: Species.SpeciesID) -> PokemonFormData:
	if not _loaded:
		return null
	return _form_cache.get(int(form_species_id)) as PokemonFormData

func get_form_base_species(form_species_id: Species.SpeciesID) -> PokemonDataStruct:
	return _form_base_cache.get(int(form_species_id)) as PokemonDataStruct

func has_species(species_id: Species.SpeciesID) -> bool:
	return _loaded and (_cache.has(int(species_id)) or _form_cache.has(int(species_id)))

func has_form(form_species_id: Species.SpeciesID) -> bool:
	return _loaded and _form_cache.has(int(form_species_id))

func get_all_species() -> Array[PokemonDataStruct]:
	var result: Array[PokemonDataStruct] = []
	for value: Variant in _cache.values():
		var data: PokemonDataStruct = value as PokemonDataStruct
		if data != null:
			result.append(data)
	return result

func get_species_count() -> int:
	return _cache.size()

func get_form_count() -> int:
	return _form_cache.size()

func get_load_errors() -> Array[String]:
	return _errors.duplicate()

func get_load_warnings() -> Array[String]:
	return _warnings.duplicate()

func reload_database() -> void:
	load_database()

## Siempre comienza desde cero. Esto evita falsos duplicados si load_database()
## se llama más de una vez por el autoload, una escena o una recarga de scripts.
func load_database() -> void:
	if _loading:
		return

	_loading = true
	_loaded = false
	_cache.clear()
	_form_cache.clear()
	_form_base_cache.clear()
	_resolved_cache.clear()
	_errors.clear()
	_warnings.clear()

	_load_from_subfolder(SPECIES_PATH)

	_loaded = true
	_loading = false
	database_loaded.emit(_cache.size())
	print("SpeciesDB: %d especies y %d formas cargadas." % [_cache.size(), _form_cache.size()])

	if not _errors.is_empty():
		print("SpeciesDB: %d errores:" % _errors.size())
		for message: String in _errors:
			push_error("  ✖ %s" % message)


func _load_from_subfolder(path: String) -> void:
	for entry: String in ResourceLoader.list_directory(path):
		if entry.begins_with("."):
			continue
		var full_path: String = path.path_join(entry)
		if entry.ends_with("/"):
			_load_from_subfolder(full_path)
		elif entry.ends_with(FILE_EXTENSION):
			_load_species_file(full_path)

func _load_species_file(path: String) -> void:
	var resource: Resource = ResourceLoader.load(path)
	if resource == null:
		_errors.append("'%s' no se pudo cargar." % path)
		return

	if not resource is PokemonDataStruct:
		_errors.append("'%s' no es un PokemonDataStruct válido." % path)
		return

	var data: PokemonDataStruct = resource as PokemonDataStruct
	var id: int = int(data.species_id)
	if id == int(Species.SpeciesID.SPECIES_NONE):
		_errors.append("'%s' tiene SPECIES_NONE." % path)
		return

	var validation_errors: Array[String] = data._validate()
	for validation_error: String in validation_errors:
		_errors.append("'%s': %s" % [path, validation_error])
	if not validation_errors.is_empty():
		return

	if _cache.has(id) or _form_cache.has(id):
		_errors.append("ID %d duplicado al cargar '%s'." % [id, path])
		return

	_cache[id] = data
	_index_forms(data, path)

func _index_forms(base_species: PokemonDataStruct, path: String) -> void:
	for form: PokemonFormData in base_species.forms:
		if form == null:
			continue
		var form_id: int = int(form.species_id)
		if form_id == int(Species.SpeciesID.SPECIES_NONE):
			# Recursos creados con el modelo anterior todavía pueden tener
			# solo form_id. Se conservan, pero no pueden resolverse por enum.
			_warnings.append("'%s': la forma '%s' no tiene SpeciesID." % [path, str(form.form_id)])
			continue
		if form_id == int(base_species.species_id):
			_errors.append("'%s': una forma no puede reutilizar el ID de su especie base (%d)." % [path, form_id])
			continue
		if _cache.has(form_id) or _form_cache.has(form_id):
			_errors.append("ID de forma %d duplicado en '%s'." % [form_id, path])
			continue
		_form_cache[form_id] = form
		_form_base_cache[form_id] = base_species

func _build_resolved_species(base_species: PokemonDataStruct, form: PokemonFormData) -> PokemonDataStruct:
	if base_species == null or form == null:
		return base_species

	var resolved: PokemonDataStruct = base_species.duplicate(true) as PokemonDataStruct
	# El nombre de especie no cambia al usar una forma. La forma queda
	# disponible mediante get_form() / get_active_form().
	resolved.species_id = form.species_id
	resolved.species_name = base_species.species_name

	if form.override_types:
		if form.type_1 != PokemonData.Type.TYPE_NONE:
			resolved.type_1 = form.type_1
		if form.type_2 != PokemonData.Type.TYPE_NONE:
			resolved.type_2 = form.type_2

	if form.override_stats:
		resolved.base_hp = form.base_hp
		resolved.base_attack = form.base_attack
		resolved.base_defense = form.base_defense
		resolved.base_speed = form.base_speed
		resolved.base_sp_attack = form.base_sp_attack
		resolved.base_sp_defense = form.base_sp_defense

	if form.inherit_base_moves:
		resolved.level_up_moves = _merge_level_up_moves(base_species.level_up_moves, form.level_up_moves)
		resolved.teachable_moves = _merge_move_ids(base_species.teachable_moves, form.teachable_moves)
		resolved.egg_moves = _merge_move_ids(base_species.egg_moves, form.egg_moves)
	else:
		resolved.level_up_moves = form.level_up_moves.duplicate(true)
		resolved.teachable_moves = form.teachable_moves.duplicate()
		resolved.egg_moves = form.egg_moves.duplicate()

	if form.override_pokedex:
		resolved.category_name = form.category_name
		resolved.description = form.description
		resolved.height = form.height
		resolved.weight = form.weight

	if form.override_graphics:
		if form.front_sprite != null:
			resolved.front_sprite = form.front_sprite
		if form.front_sprite_shiny != null:
			resolved.front_sprite_shiny = form.front_sprite_shiny
		if form.back_sprite != null:
			resolved.back_sprite = form.back_sprite
		if form.back_sprite_shiny != null:
			resolved.back_sprite_shiny = form.back_sprite_shiny
		if form.icon_sprite != null:
			resolved.icon_sprite = form.icon_sprite
		if form.cry != null:
			resolved.cry = form.cry
		resolved.front_sprite_offset = form.front_sprite_offset
		resolved.back_sprite_offset = form.back_sprite_offset

	if form.inherit_base_evolutions:
		resolved.evolutions = base_species.evolutions.duplicate(true)
		for rule: EvolutionData in form.evolutions:
			if rule != null:
				resolved.evolutions.append(rule.duplicate(true) as EvolutionData)
	else:
		resolved.evolutions = form.evolutions.duplicate(true)

	return resolved

func _merge_move_ids(base_moves: Array[Moves.MoveId], form_moves: Array[Moves.MoveId]) -> Array[Moves.MoveId]:
	var result: Array[Moves.MoveId] = base_moves.duplicate()
	var seen: Dictionary = {}
	for move: Moves.MoveId in result:
		seen[int(move)] = true
	for move: Moves.MoveId in form_moves:
		if not seen.has(int(move)):
			result.append(move)
			seen[int(move)] = true
	return result

func _merge_level_up_moves(base_moves: Array[LevelUpMove], form_moves: Array[LevelUpMove]) -> Array[LevelUpMove]:
	var result: Array[LevelUpMove] = base_moves.duplicate(true)
	var seen: Dictionary = {}
	for move: LevelUpMove in result:
		if move != null:
			seen["%d:%d" % [move.level, int(move.move)]] = true
	for move: LevelUpMove in form_moves:
		if move == null:
			continue
		var key: String = "%d:%d" % [move.level, int(move.move)]
		if not seen.has(key):
			result.append(move.duplicate(true) as LevelUpMove)
			seen[key] = true
	return result
