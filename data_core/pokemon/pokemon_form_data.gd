@tool
extends Resource

class_name PokemonFormData

## Variante de una especie. Los campos con inherit_* usan los datos de la especie base.
@export_group("Identidad")
@export var form_id: StringName = &"base"
@export var display_name: String = "Forma base"
@export var base_species_id: Species.SpeciesID = Species.SpeciesID.SPECIES_NONE

@export_group("Datos sobrescritos")
@export var override_types: bool = false
@export var type_1: PokemonData.Type = PokemonData.Type.TYPE_NONE
@export var type_2: PokemonData.Type = PokemonData.Type.TYPE_NONE
@export var override_stats: bool = false
@export var base_hp: int = 0
@export var base_attack: int = 0
@export var base_defense: int = 0
@export var base_speed: int = 0
@export var base_sp_attack: int = 0
@export var base_sp_defense: int = 0

@export_group("Gráficos")
@export var front_sprite: Texture2D
@export var front_sprite_shiny: Texture2D
@export var back_sprite: Texture2D
@export var back_sprite_shiny: Texture2D
@export var icon_sprite: Texture2D
@export var cry: AudioStream
@export var front_sprite_offset: Vector2 = Vector2.ZERO
@export var back_sprite_offset: Vector2 = Vector2.ZERO
@export var override_graphics: bool = false

@export_group("Metadatos")
@export var tags: PackedStringArray = []
@export_multiline var notes: String = ""

func get_display_name() -> String:
	return display_name if not display_name.is_empty() else str(form_id)
