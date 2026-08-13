@tool
extends CharacterGame

class_name CharacterPlayer

@export_group("Identidad")
@export var money: int = 0
@export var name: String = ""

@export var PLAYER_ID: StringName = &"LOCALID_PLAYER"

var _sprite_overworld: EventObjects.PlayerID = EventObjects.PlayerID.NONE

@export_group("Apariencia")
@export var sprite_overworld: EventObjects.PlayerID:
	set(value):
		if _sprite_overworld != value:
			_sprite_overworld = value
			emit_changed()

	get:
		return _sprite_overworld
