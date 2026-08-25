@tool
extends RefCounted

class_name SpeciesValidator

func validate(species: PokemonDataStruct) -> Array[String]:
	if species == null:
		return ["La especie es null."]

	# Reutiliza la validación oficial del recurso para no mantener dos reglas
	# diferentes en el editor y en runtime.
	var errors: Array[String] = species._validate()

	# Validaciones cruzadas con los recursos reales.
	if species.ability_1 != AbilityId.Id.NONE and not _ability_exists(species.ability_1):
		errors.append("ability_1 no tiene un recurso .tres: %d" % int(species.ability_1))
	if species.ability_2 != AbilityId.Id.NONE and not _ability_exists(species.ability_2):
		errors.append("ability_2 no tiene un recurso .tres: %d" % int(species.ability_2))
	if species.hidden_ability != AbilityId.Id.NONE and not _ability_exists(species.hidden_ability):
		errors.append("hidden_ability no tiene un recurso .tres: %d" % int(species.hidden_ability))

	for entry: LevelUpMove in species.level_up_moves:
		if entry and not _move_exists(entry.move):
			errors.append("Movimiento de nivel sin recurso .tres: %d" % int(entry.move))

	for move_id: Moves.MoveId in species.teachable_moves:
		if move_id != Moves.MoveId.MOVE_NONE and not _move_exists(move_id):
			errors.append("Movimiento enseñable sin recurso .tres: %d" % int(move_id))

	for move_id: Moves.MoveId in species.egg_moves:
		if move_id != Moves.MoveId.MOVE_NONE and not _move_exists(move_id):
			errors.append("Movimiento huevo sin recurso .tres: %d" % int(move_id))

	return errors

func _ability_exists(id: AbilityId.Id) -> bool:
	var path: String = "res://data_core/ability/resources/"
	return _find_resource_with_id(path, "id", int(id))

func _move_exists(id: Moves.MoveId) -> bool:
	var path: String = "res://data_core/move/resources/"
	return _find_resource_with_id(path, "move_id", int(id))

func _find_resource_with_id(path: String, property_name: String, wanted_id: int) -> bool:
	var directory := DirAccess.open(path)
	if directory == null:
		return false

	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while not entry.is_empty():
		if not entry.begins_with("."):
			var full_path: String = path.path_join(entry)
			if directory.current_is_dir():
				if _find_resource_with_id(full_path, property_name, wanted_id):
					directory.list_dir_end()
					return true
			elif entry.ends_with(".tres"):
				var resource := ResourceLoader.load(full_path)
				if resource and int(resource.get(property_name)) == wanted_id:
					directory.list_dir_end()
					return true
		entry = directory.get_next()

	directory.list_dir_end()
	return false
