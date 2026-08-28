@tool
extends Resource

class_name PokemonFormData

## Variante de una especie. La forma tiene su propio SpeciesID dentro de species.gd.
## Los campos no sobrescritos se heredan de la especie base.
@export_group("Identidad")
## ID real de la forma, declarado en Species.SpeciesID.
@export var species_id: Species.SpeciesID = Species.SpeciesID.SPECIES_NONE
## Identificador legible/legacy. No se usa como identidad principal.
@export var form_id: StringName = &"base"
@export var display_name: String = "Forma base"
## ID de la especie que contiene esta forma.
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

@export_group("Movimientos")
@export var inherit_base_moves: bool = true
@export var level_up_moves: Array[LevelUpMove] = []
@export var teachable_moves: Array[Moves.MoveId] = []
@export var egg_moves: Array[Moves.MoveId] = []

@export_group("Evoluciones")
@export var inherit_base_evolutions: bool = true
@export var evolutions: Array[EvolutionData] = []

@export_group("Pokédex de la forma")
@export var override_pokedex: bool = false
@export var category_name: String = ""
@export_multiline var description: String = ""
@export var height: int = 0
@export var weight: int = 0

@export_group("Metadatos")
@export var tags: PackedStringArray = []
@export_multiline var notes: String = ""

func get_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	if species_id != Species.SpeciesID.SPECIES_NONE:
		return "ID %d" % int(species_id)
	return str(form_id)
