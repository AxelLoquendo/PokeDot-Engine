@tool
extends CharacterGame
class_name CharacterNpc

## One and only autonomous selector. Its selected type owns an internal
## MovementAction state machine; ApplyMovement is a separate temporary queue.
@export_group("Identidad")
@export var nombre: String = "NPC"
@export var npc_id: StringName
var _sprite_overworld: EventObjects.NpcID = EventObjects.NpcID.NONE
@export var sprite_overworld: EventObjects.NpcID:
	set(value):
		if _sprite_overworld == value: return
		_sprite_overworld = value
		emit_changed()
	get: return _sprite_overworld

@export_group("Apariencia")
enum DireccionInicial { ABAJO, ARRIBA, IZQUIERDA, DERECHA }
@export var direccion_inicial: DireccionInicial = DireccionInicial.ABAJO

@export_group("Movimiento autónomo")
## Legacy enum name is retained for resource serialization. This is the sole
## user-facing base movement selector.
@export var comportamiento: MovementTypes.AutonomousBehavior = MovementTypes.AutonomousBehavior.QUIETO

@export_group("Seguimiento y patrulla")
@export_range(0, 20, 1) var rango_seguimiento: int = 1
@export_range(0, 20, 1) var distancia_patrulla: int = 0
@export_range(0.0, 10.0, 0.1) var tiempo_espera: float = 0.0

@export_group("Scripts")
@export var scripts: ScriptCmdTextFile
