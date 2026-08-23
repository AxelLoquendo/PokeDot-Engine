@tool
extends Resource

class_name PokemonDataStruct

# Species
@export_group("Species")
@export var national_dex_number: int
@export var regional_dex_number: int
@export var species_name: String
@export var species_id: Species.SpeciesID = Species.SpeciesID.SPECIES_NONE

# Base Stats
@export_group("Base Stats")
@export var base_hp: int
@export var base_attack: int
@export var base_defense: int
@export var base_speed: int
@export var base_sp_attack: int
@export var base_sp_defense: int

@export var evYield_HP: int
@export var evYield_Attack: int
@export var evYield_Defense: int
@export var evYield_Speed: int
@export var evYield_SpAttack: int
@export var evYield_SpDefense: int

# Types
@export_group("Types")
@export var type_1: PokemonData.Type
@export var type_2: PokemonData.Type = PokemonData.Type.TYPE_NONE

# General Data
@export_group("General Data")
@export var catch_rate: int
@export var exp_yield: int
@export var friendship: int
@export var growth_rate: PokemonData.GrowthRate

# Pokédex
@export_group("Pokédex")
@export var category_name: String
@export_multiline var description: String
@export var height: int
@export var weight: int
@export var body_color: PokemonData.BodyColor

# Graphics
@export_group("Graphics")
@export var front_sprite: Texture2D
@export var front_sprite_shiny: Texture2D
@export var back_sprite: Texture2D
@export var back_sprite_shiny: Texture2D
@export var icon_sprite: Texture2D
@export var overworld_scene: Texture2D

@export var front_sprite_female: Texture2D
@export var front_sprite_shiny_female: Texture2D
@export var back_sprite_female: Texture2D
@export var back_sprite_shiny_female: Texture2D
@export var icon_sprite_female: Texture2D
@export var overworld_scene_female: Texture2D

# Learnsets
@export_group("Learnsets")
@export var level_up_moves: Array[LevelUpMove]
@export var teachable_moves: Array[Moves.MoveId]
@export var egg_moves: Array[Moves.MoveId]

# Evolution
@export_group("Evolutions")
@export var evolutions: Array[EvolutionData]

# Abilities
@export_group("Abilities")
@export var ability_1: AbilityId.Id = AbilityId.Id.NONE
@export var ability_2: AbilityId.Id = AbilityId.Id.NONE
@export var hidden_ability: AbilityId.Id = AbilityId.Id.NONE

# Items
@export_group("Items")
@export var item_common: Items.ItemId
@export var item_rare: Items.ItemId

# Flags
@export_group("Flags")
@export var is_legendary: bool = false
@export var is_mythical: bool = false
@export var is_ultra_beast: bool = false

# Breeding
@export_group("Breeding")
@export var egg_group_1: PokemonData.EggGroup
@export var egg_group_2: PokemonData.EggGroup
@export var egg_cycles: int
@export var hatch_species: Species.SpeciesID

# Battle Position
@export_group("Battle Position")
@export var front_sprite_offset: Vector2 = Vector2.ZERO
@export var back_sprite_offset: Vector2 = Vector2.ZERO

# Gender
@export_group("Gender")
@export var gender_ratio: PokemonData.GenderRatio

# cry
@export_group("cry")
@export var cry: AudioStream

## 16 = estilo más fino; 32 = pasos más grandes (elige según tu UI de combate)
const BATTLE_OFFSET_SCALE: float = 32.0

func get_front_sprite_offset_px() -> Vector2:
	return front_sprite_offset * BATTLE_OFFSET_SCALE

func get_back_sprite_offset_px() -> Vector2:
	return back_sprite_offset * BATTLE_OFFSET_SCALE

func _validate() -> Array[String]:
	var errors: Array[String] = []

	# ─────────────────────────────
	# Identidad
	# ─────────────────────────────

	if species_id == Species.SpeciesID.SPECIES_NONE:
		errors.append("species_id no puede ser SPECIES_NONE.")

	if species_name.is_empty():
		errors.append("species_name está vacío.")

	if national_dex_number < 1:
		errors.append("national_dex_number debe ser mayor o igual a 1.")

	if regional_dex_number < 0:
		errors.append("regional_dex_number no puede ser negativo.")

	# ─────────────────────────────
	# Estadísticas base
	# ─────────────────────────────

	if base_hp < 1:
		errors.append("base_hp debe ser mayor o igual a 1.")

	if base_attack < 1:
		errors.append("base_attack debe ser mayor o igual a 1.")

	if base_defense < 1:
		errors.append("base_defense debe ser mayor o igual a 1.")

	if base_speed < 1:
		errors.append("base_speed debe ser mayor o igual a 1.")

	if base_sp_attack < 1:
		errors.append("base_sp_attack debe ser mayor o igual a 1.")

	if base_sp_defense < 1:
		errors.append("base_sp_defense debe ser mayor o igual a 1.")


	# ─────────────────────────────
	# Tipos
	# ─────────────────────────────

	if not _enum_contains_value(PokemonData.Type, type_1):
		errors.append(
			"type_1 tiene un valor inválido: %d." % type_1
		)

	if not _enum_contains_value(PokemonData.Type, type_2):
		errors.append(
			"type_2 tiene un valor inválido: %d." % type_2
		)

	if type_1 == PokemonData.Type.TYPE_NONE:
		errors.append("type_1 no puede ser TYPE_NONE.")

	if type_2 == type_1 and type_2 != PokemonData.Type.TYPE_NONE:
		errors.append("type_1 y type_2 no pueden ser iguales.")


	# ─────────────────────────────
	# Datos generales
	# ─────────────────────────────

	if catch_rate < 0 or catch_rate > 255:
		errors.append(
			"catch_rate debe estar entre 0 y 255."
		)

	if exp_yield < 0:
		errors.append(
			"exp_yield no puede ser negativo."
		)

	if friendship < 0 or friendship > 255:
		errors.append(
			"friendship debe estar entre 0 y 255."
		)

	if not _enum_contains_value(PokemonData.GrowthRate, growth_rate):
		errors.append(
			"growth_rate tiene un valor inválido."
		)


	# ─────────────────────────────
	# Pokédex
	# ─────────────────────────────

	if category_name.is_empty():
		errors.append("category_name está vacío.")

	if description.is_empty():
		errors.append("description está vacío.")

	if height < 0:
		errors.append("height no puede ser negativo.")

	if weight < 0:
		errors.append("weight no puede ser negativo.")

	if not _enum_contains_value(PokemonData.BodyColor, body_color):
		errors.append(
			"body_color tiene un valor inválido."
		)


	# ─────────────────────────────
	# Learnset
	# ─────────────────────────────

	for i: int in range(level_up_moves.size()):

		var entry: LevelUpMove = level_up_moves[i]

		if entry == null:
			errors.append(
				"level_up_moves[%d] es null." % i
			)
			continue

		if entry.level < 1 or entry.level > 100:
			errors.append(
				"level_up_moves[%d] tiene un nivel inválido: %d."
				% [i, entry.level]
			)

		if entry.move == Moves.MoveId.MOVE_NONE:
			errors.append(
				"level_up_moves[%d] tiene MOVE_NONE."
				% i
			)


	# ─────────────────────────────
	# Evoluciones
	# ─────────────────────────────

	for i: int in range(evolutions.size()):

		var evolution: EvolutionData = evolutions[i]

		if evolution == null:
			errors.append(
				"evolutions[%d] es null." % i
			)
			continue

		if not _enum_contains_value(
			PokemonData.EvolutionMethods,
			evolution.method
		):
			errors.append(
				"evolutions[%d] tiene un método inválido."
				% i
			)

		if evolution.target_species == Species.SpeciesID.SPECIES_NONE:
			errors.append(
				"evolutions[%d] tiene target_species = SPECIES_NONE."
				% i
			)

		if not _enum_contains_value(
			PokemonData.EvolutionConditions,
			evolution.condition
		):
			errors.append(
				"evolutions[%d] tiene una condición inválida."
				% i
			)


	# ─────────────────────────────
	# Habilidades
	# ─────────────────────────────

	if not _enum_contains_value(AbilityId.Id, ability_1):
		errors.append("ability_1 tiene un valor inválido.")

	if not _enum_contains_value(AbilityId.Id, ability_2):
		errors.append("ability_2 tiene un valor inválido.")

	if not _enum_contains_value(AbilityId.Id, hidden_ability):
		errors.append("hidden_ability tiene un valor inválido.")


	# ─────────────────────────────
	# Grupos huevo
	# ─────────────────────────────

	if not _enum_contains_value(
		PokemonData.EggGroup,
		egg_group_1
	):
		errors.append("egg_group_1 tiene un valor inválido.")

	if not _enum_contains_value(
		PokemonData.EggGroup,
		egg_group_2
	):
		errors.append("egg_group_2 tiene un valor inválido.")

	if egg_cycles < 0:
		errors.append(
			"egg_cycles no puede ser negativo."
		)


	# ─────────────────────────────
	# Especie de eclosión
	# ─────────────────────────────

	if hatch_species == Species.SpeciesID.SPECIES_NONE:
		errors.append(
			"hatch_species no puede ser SPECIES_NONE."
		)


	# ─────────────────────────────
	# Género
	# ─────────────────────────────

	if not _enum_contains_value(
		PokemonData.GenderRatio,
		gender_ratio
	):
		errors.append(
			"gender_ratio tiene un valor inválido."
		)


	return errors


func _enum_contains_value(enum_dictionary: Dictionary, value: int) -> bool:
	return value in enum_dictionary.values()
