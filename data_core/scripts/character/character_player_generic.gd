@tool
extends CharacterGame

class_name CharacterPlayer

@export_group("Identidad")
@export var money: int = 0
@export var name: String = ""

@export var PLAYER_ID: StringName = &"LOCALID_PLAYER"

@export_group("Datos de partida")
@export var bag: Bag = Bag.new()
@export var party: Array[PokemonInstance] = []


func add_pokemon(pokemon: PokemonInstance) -> bool:
	if pokemon == null or party.size() >= 6:
		return false
	party.append(pokemon)
	return true

var _sprite_overworld: EventObjects.PlayerID = EventObjects.PlayerID.NONE

@export_group("Apariencia")
@export var sprite_overworld: EventObjects.PlayerID:
	set(value):
		if _sprite_overworld != value:
			_sprite_overworld = value
			emit_changed()

	get:
		return _sprite_overworld
