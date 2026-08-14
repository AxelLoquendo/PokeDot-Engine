extends Resource
class_name PokemonInstance

## Datos variables de una criatura concreta. No guardes aquí estadísticas
## base ni sprites: esos datos viven en PokemonDataStruct de la especie.
@export var species_id: Species.SpeciesID = Species.SpeciesID.SPECIES_NONE
@export_range(1, 100) var level: int = 1
@export var experience: int = 0
@export var nickname: String = ""
@export var ability_id: AbilityId.Id = AbilityId.Id.NONE
@export var held_item: Items.ItemId = Items.ItemId.ITEM_NONE
@export var moves: Array[PokemonMoveSlot] = []


func get_species() -> PokemonDataStruct:
	return SpeciesDatabase.get_species(species_id)


func get_display_name() -> String:
	if not nickname.strip_edges().is_empty():
		return nickname
	var species: PokemonDataStruct = get_species()
	return species.species_name if species else "???"


func learn_move(move_id: Moves.MoveId) -> bool:
	if move_id == Moves.MoveId.MOVE_NONE:
		return false
	for slot: PokemonMoveSlot in moves:
		if slot and slot.move_id == move_id:
			return false
	var new_slot: PokemonMoveSlot = PokemonMoveSlot.new()
	new_slot.setup(move_id)
	if moves.size() >= 4:
		moves.pop_front()
	moves.append(new_slot)
	return true


func restore_pp() -> void:
	for slot: PokemonMoveSlot in moves:
		if slot and not slot.is_empty():
			var move_data: MoveData = MoveDatabase.get_move(slot.move_id)
			if move_data:
				slot.current_pp = move_data.pp


static func create(species: Species.SpeciesID, initial_level: int = 5) -> PokemonInstance:
	var pokemon: PokemonInstance = PokemonInstance.new()
	pokemon.species_id = species
	pokemon.level = clampi(initial_level, 1, 100)
	var data: PokemonDataStruct = SpeciesDatabase.get_species(species)
	if data == null:
		return pokemon
	pokemon.ability_id = data.ability_1
	var learnable: Array[LevelUpMove] = data.level_up_moves.duplicate()
	learnable.sort_custom(func(a: LevelUpMove, b: LevelUpMove) -> bool: return a.level < b.level)
	for entry: LevelUpMove in learnable:
		if entry and entry.level <= pokemon.level:
			pokemon.learn_move(entry.move)
	return pokemon
