extends Resource
class_name TrainerPokemon

## Pokémon de un entrenador tal como está en su archivo.

@export var species_id: Species.SpeciesID = Species.SpeciesID.SPECIES_NONE
@export var nickname: String = ""
@export_range(1, 100) var level: int = 100
@export var held_item: Items.ItemId = Items.ItemId.ITEM_NONE
## NONE = primera habilidad de la especie.
@export var ability_id: AbilityId.Id = AbilityId.Id.NONE
## Serious si no se indica.
@export var nature: PokemonData.Nature = PokemonData.Nature.NATURE_SERIOUS
## -1 = según la especie.
@export_enum("Según especie:-1", "Macho:0", "Hembra:1") var gender: int = -1
@export var shiny: bool = false
## -1 = amistad base de la especie.
@export_range(-1, 255) var friendship: int = -1
## NONE = el tipo Tera por defecto.
@export var tera_type: PokemonData.Type = PokemonData.Type.TYPE_NONE
## HP, Atk, Def, Spe, SpAtk, SpDef.
@export var ivs: Array[int] = [31, 31, 31, 31, 31, 31]
@export var evs: Array[int] = [0, 0, 0, 0, 0, 0]
## Vacío = los de su nivel.
@export var moves: Array[Moves.MoveId] = []


func create_instance() -> PokemonInstance:
	var mon: PokemonInstance = PokemonInstance.create(species_id, level)
	if SpeciesDatabase.has_form(species_id):
		var form: PokemonFormData = SpeciesDatabase.get_form(species_id)
		if form != null:
			mon.form_id = form.form_id

	mon.nickname = nickname
	mon.held_item = held_item
	mon.nature = nature
	mon.shiny = shiny
	if gender >= 0:
		mon.gender = gender as PokemonData.Gender
	if friendship >= 0:
		mon.friendship = friendship
	if tera_type != PokemonData.Type.TYPE_NONE:
		mon.tera_type = tera_type

	if ability_id != AbilityId.Id.NONE:
		mon.ability_id = ability_id
	else:
		var data: PokemonDataStruct = mon.get_species()
		if data != null and data.ability_1 != AbilityId.Id.NONE:
			mon.ability_id = data.ability_1

	mon.ivs = ivs.duplicate()
	mon.evs = evs.duplicate()

	if not moves.is_empty():
		mon.moves.clear()
		for move_id: Moves.MoveId in moves:
			mon.learn_move(move_id)

	mon.recalculate_stats()
	mon.current_hp = mon.max_hp
	return mon
