@tool
extends CharacterGame
class_name CharacterPlayer

@export_group("Identidad")
@export var money: int = 3000
@export var name: String = ""
@export var gender: int = 0  # 0 boy, 1 neutral, 2 girl
@export var gender_option: GenderOption
@export var PLAYER_ID: StringName = &"LOCALID_PLAYER"

@export_group("Datos de partida")
@export var bag: Bag = Bag.new()
@export var party: Array[PokemonInstance] = []
@export var pokedex: PokedexData = PokedexData.new()
@export var created_at: String = ""
@export var trainer_id: int = 0
@export var registered_item: Items.ItemId = Items.ItemId.ITEM_NONE

var _sprite_overworld: EventObjects.PlayerID = EventObjects.PlayerID.NONE
@export_group("Apariencia")
@export var sprite_overworld: EventObjects.PlayerID:
	set(value):
		if _sprite_overworld != value:
			_sprite_overworld = value
			emit_changed()
	get:
		return _sprite_overworld


func add_pokemon(pokemon: PokemonInstance) -> bool:
	if pokemon == null or party.size() >= 6:
		return false
	party.append(pokemon)
	return true


## Punto único para consumir un objeto de la mochila sobre un Pokémon. Las
## interfaces solo necesitan elegir el objeto y el objetivo; esta función evita
## que cada menú reimplemente curación, PP y evolución de forma distinta.
func use_bag_item_on_pokemon(item_id: Items.ItemId, pokemon: PokemonInstance, move_slot_index: int = -1) -> ItemUseResolver.Result:
	var failed: ItemUseResolver.Result = ItemUseResolver.Result.new()
	if bag == null or not bag.has_item(item_id):
		failed.message = "No queda ese objeto en la mochila."
		return failed
	var item: ItemData = ItemDatabase.get_item(item_id)
	if item == null:
		failed.message = "No se pudieron cargar los datos del objeto."
		return failed
	var result: ItemUseResolver.Result = ItemUseResolver.use_on_pokemon(item, pokemon, null, move_slot_index)
	if not result.success:
		return result
	if result.evolved != null:
		var evo_context: EvolutionContext = EvolutionContext.new(pokemon)
		evo_context.mode = PokemonData.EvolutionMode.EVO_MODE_ITEM_USE
		evo_context.used_item_id = item_id
		pokemon.apply_evolution(result.evolved, evo_context)
	if result.consume_item:
		bag.remove_item(item_id)
	return result

func ensure_pokedex() -> PokedexData:
	if pokedex == null:
		pokedex = PokedexData.new()
	return pokedex
