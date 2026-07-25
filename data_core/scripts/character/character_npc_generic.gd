@tool
extends CharacterGame

class_name CharacterNpc

enum Comportamiento {
	QUIETO,
	PATRULLA_HORIZONTAL,
	PATRULLA_VERTICAL,
	RANDOM_WALK,
	LOOK_AROUND,
}

enum DireccionInicial {
	ABAJO,
	ARRIBA,
	IZQUIERDA,
	DERECHA
}

@export_group("Identidad")
@export var nombre: String = "NPC"
@export var npc_id: StringName
var _sprite_overworld: EventObjects.NpcID = EventObjects.NpcID.NONE

@export var sprite_overworld: EventObjects.NpcID:
	set(value):
		if _sprite_overworld == value:
			return

		_sprite_overworld = value
		print("emit_changed()")
		emit_changed()

	get:
		return _sprite_overworld

@export_group("Apariencia")
@export var direccion_inicial: DireccionInicial = DireccionInicial.ABAJO

@export_group("Comportamiento")
@export var comportamiento: Comportamiento = Comportamiento.QUIETO

@export_group("Patrulla")
@export_range(0, 20, 1) var distancia_patrulla: int = 0
@export_range(0.0, 10.0, 0.1) var tiempo_espera: float = 0.0

@export_group("Interacción")
@export var dialogue: Dialogue
