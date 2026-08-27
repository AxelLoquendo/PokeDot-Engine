@tool
extends RefCounted

class_name PokemonFormResolver

## Resuelve una forma identificada por su SpeciesID sin modificar el recurso base.
## form_id se conserva únicamente como compatibilidad con partidas/recursos legacy.

static func get_species_data(pokemon: PokemonInstance) -> PokemonDataStruct:
	if pokemon == null:
		return null
	return SpeciesDatabase.get_base_species(pokemon.species_id)

static func get_form(pokemon: PokemonInstance) -> PokemonFormData:
	if pokemon == null:
		return null

	# Modelo nuevo: el species_id de la instancia es directamente el ID de la forma.
	var form: PokemonFormData = SpeciesDatabase.get_form(pokemon.species_id)
	if form != null:
		return form

	# Compatibilidad: recursos/partidas anteriores que usaban form_id textual.
	var species: PokemonDataStruct = get_species_data(pokemon)
	if species == null or pokemon.form_id.is_empty() or pokemon.form_id == &"base":
		return null
	for legacy_form: PokemonFormData in species.forms:
		if legacy_form != null and legacy_form.form_id == pokemon.form_id:
			return legacy_form
	return null

static func get_form_id(pokemon: PokemonInstance) -> StringName:
	var form: PokemonFormData = get_form(pokemon)
	if form != null and not form.form_id.is_empty():
		return form.form_id
	return pokemon.form_id if pokemon != null else &"base"

static func get_form_species_id(pokemon: PokemonInstance) -> Species.SpeciesID:
	if pokemon == null:
		return Species.SpeciesID.SPECIES_NONE
	if SpeciesDatabase.has_form(pokemon.species_id):
		return pokemon.species_id
	var form: PokemonFormData = get_form(pokemon)
	return form.species_id if form != null else Species.SpeciesID.SPECIES_NONE

static func get_type_1(pokemon: PokemonInstance) -> PokemonData.Type:
	var species: PokemonDataStruct = get_species_data(pokemon)
	var form: PokemonFormData = get_form(pokemon)
	if form != null and form.override_types and form.type_1 != PokemonData.Type.TYPE_NONE:
		return form.type_1
	return species.type_1 if species != null else PokemonData.Type.TYPE_NONE

static func get_type_2(pokemon: PokemonInstance) -> PokemonData.Type:
	var species: PokemonDataStruct = get_species_data(pokemon)
	var form: PokemonFormData = get_form(pokemon)
	if form != null and form.override_types and form.type_2 != PokemonData.Type.TYPE_NONE:
		return form.type_2
	return species.type_2 if species != null else PokemonData.Type.TYPE_NONE

static func get_front_sprite(pokemon: PokemonInstance, shiny: bool = false) -> Texture2D:
	var species: PokemonDataStruct = get_species_data(pokemon)
	var form: PokemonFormData = get_form(pokemon)
	if form != null and form.override_graphics:
		var form_sprite: Texture2D = form.front_sprite_shiny if shiny else form.front_sprite
		if form_sprite != null:
			return form_sprite
	if species == null:
		return null
	return species.front_sprite_shiny if shiny else species.front_sprite

static func get_back_sprite(pokemon: PokemonInstance, shiny: bool = false) -> Texture2D:
	var species: PokemonDataStruct = get_species_data(pokemon)
	var form: PokemonFormData = get_form(pokemon)
	if form != null and form.override_graphics:
		var form_sprite: Texture2D = form.back_sprite_shiny if shiny else form.back_sprite
		if form_sprite != null:
			return form_sprite
	if species == null:
		return null
	return species.back_sprite_shiny if shiny else species.back_sprite

static func get_icon_sprite(pokemon: PokemonInstance) -> Texture2D:
	var species: PokemonDataStruct = get_species_data(pokemon)
	var form: PokemonFormData = get_form(pokemon)
	if form != null and form.override_graphics and form.icon_sprite != null:
		return form.icon_sprite
	return species.icon_sprite if species != null else null

static func get_cry(pokemon: PokemonInstance) -> AudioStream:
	var species: PokemonDataStruct = get_species_data(pokemon)
	var form: PokemonFormData = get_form(pokemon)
	if form != null and form.override_graphics and form.cry != null:
		return form.cry
	return species.cry if species != null else null

static func get_front_sprite_offset(pokemon: PokemonInstance) -> Vector2:
	var species: PokemonDataStruct = get_species_data(pokemon)
	var form: PokemonFormData = get_form(pokemon)
	if form != null and form.override_graphics:
		return form.front_sprite_offset
	return species.front_sprite_offset if species != null else Vector2.ZERO

static func get_back_sprite_offset(pokemon: PokemonInstance) -> Vector2:
	var species: PokemonDataStruct = get_species_data(pokemon)
	var form: PokemonFormData = get_form(pokemon)
	if form != null and form.override_graphics:
		return form.back_sprite_offset
	return species.back_sprite_offset if species != null else Vector2.ZERO

static func get_front_sprite_offset_px(pokemon: PokemonInstance) -> Vector2:
	return get_front_sprite_offset(pokemon) * PokemonDataStruct.BATTLE_OFFSET_SCALE

static func get_back_sprite_offset_px(pokemon: PokemonInstance) -> Vector2:
	return get_back_sprite_offset(pokemon) * PokemonDataStruct.BATTLE_OFFSET_SCALE

static func get_base_stat(pokemon: PokemonInstance, stat: PokemonInstance.Stat) -> int:
	var species: PokemonDataStruct = get_species_data(pokemon)
	var form: PokemonFormData = get_form(pokemon)
	if form != null and form.override_stats:
		match stat:
			PokemonInstance.Stat.HP: return form.base_hp
			PokemonInstance.Stat.ATTACK: return form.base_attack
			PokemonInstance.Stat.DEFENSE: return form.base_defense
			PokemonInstance.Stat.SPEED: return form.base_speed
			PokemonInstance.Stat.SP_ATTACK: return form.base_sp_attack
			PokemonInstance.Stat.SP_DEFENSE: return form.base_sp_defense
	return pokemon.get_base_stat(stat, species) if pokemon != null and species != null else 0
