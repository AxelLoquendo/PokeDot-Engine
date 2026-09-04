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

	var form_ids: Dictionary = {}
	for form: PokemonFormData in species.forms:
		if form == null:
			continue
		var form_id: int = int(form.species_id)
		if form_id == int(Species.SpeciesID.SPECIES_NONE):
			errors.append("La forma '%s' no tiene SpeciesID en species.gd." % str(form.form_id))
			continue
		if form_id == int(species.species_id):
			errors.append("La forma '%s' reutiliza el ID de la especie base." % form.get_display_name())
		if form_ids.has(form_id):
			errors.append("ID de forma duplicado dentro de la especie: %d" % form_id)
		form_ids[form_id] = true
		if form.base_species_id != Species.SpeciesID.SPECIES_NONE and int(form.base_species_id) != int(species.species_id):
			errors.append("La forma %d apunta a otra especie base (%d)." % [form_id, int(form.base_species_id)])
		if form.override_abilities:
			for ability: AbilityId.Id in [form.ability_1, form.ability_2, form.hidden_ability]:
				if ability != AbilityId.Id.NONE and not int(ability) in AbilityId.Id.values():
					errors.append("La forma %d tiene una habilidad inválida: %d." % [form_id, int(ability)])
		if not _species_enum_id_exists(form_id):
			errors.append("La forma %d no está declarada en species.gd." % form_id)
		if form.override_pokedex:
			if form.category_name.is_empty():
				errors.append("La forma %d tiene la categoría de Pokédex vacía." % form_id)
			if form.description.is_empty():
				errors.append("La forma %d tiene la descripción de Pokédex vacía." % form_id)
		for move: Moves.MoveId in form.teachable_moves:
			if move != Moves.MoveId.MOVE_NONE and not _move_exists(move):
				errors.append("MT/MO de la forma %d sin recurso .tres: %d" % [form_id, int(move)])
		for move: Moves.MoveId in form.egg_moves:
			if move != Moves.MoveId.MOVE_NONE and not _move_exists(move):
				errors.append("Movimiento huevo de la forma %d sin recurso .tres: %d" % [form_id, int(move)])
		for level_move: LevelUpMove in form.level_up_moves:
			if level_move != null and not _move_exists(level_move.move):
				errors.append("Movimiento de nivel de la forma %d sin recurso .tres: %d" % [form_id, int(level_move.move)])

	return errors

func _species_enum_id_exists(id: int) -> bool:
	if not FileAccess.file_exists("res://data_core/pokemon/species.gd"):
		return false
	var content := FileAccess.get_file_as_string("res://data_core/pokemon/species.gd")
	return content.contains("= %d," % id) or content.contains("= %d\\n" % id)

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
