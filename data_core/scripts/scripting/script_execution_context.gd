extends RefCounted
class_name ScriptExecutionContext

## Contexto pasado a cada comando durante la ejecución
## Contiene referencias a los nodos relevantes

var npc: Node2D = null          ## El NPC que ejecuta el script
var player: Node2D = null       ## El jugador
var map: Node = null            ## El mapa actual
var is_waiting: bool = false    ## True si el script está esperando un evento asíncrono
var variables: Dictionary[String, Variant] = {}  ## Variables temporales del script
var runner: ScriptRunner = null
static var global_flags: Dictionary[String, Variant] = {}


func _init(npc_node: Node2D = null, player_node: Node2D = null, map_node: Node = null) -> void:
	npc = npc_node
	player = player_node
	map = map_node


## Obtiene el NPC como CharacterNpc si es posible
func get_npc_data() -> CharacterNpc:
	var controller: CharacterController = npc as CharacterController
	if controller:
		return controller.character_data as CharacterNpc
	return null


## Obtiene el controller del NPC
func get_npc_controller() -> CharacterController:
	return npc as CharacterController


## Obtiene el controller del jugador
func get_player_controller() -> Node2D:
	return player


## Verifica si el jugador está frente al NPC
func is_player_facing_npc() -> bool:
	if not npc or not player:
		return false
	
	var npc_pos: Vector2 = npc.position
	var player_pos: Vector2 = player.position
	var _direction: Vector2 = (npc_pos - player_pos).normalized()
	
	# Implementar lógica de dirección según tu sistema
	return true  ## Placeholder


## Mueve al NPC a una casilla específica
func move_npc_to_tile(tile_pos: Vector2i, wait: bool = true) -> void:
	if not npc:
		return
	var controller: CharacterController = get_npc_controller()
	if controller and controller.has_method("mover_a_casilla"):
		controller.call("mover_a_casilla", tile_pos)
		if wait:
			is_waiting = true


## Mueve al jugador a una casilla específica
func move_player_to_tile(tile_pos: Vector2i, wait: bool = true) -> void:
	if not player:
		return
	var controller: Node = player
	if controller and controller.has_method("mover_a_casilla"):
		controller.call("mover_a_casilla", tile_pos)
		if wait:
			is_waiting = true


## Hace que el NPC mire en una dirección
func look_npc_direction(direction: Vector2i) -> void:
	if not npc:
		return
	var controller: CharacterController = get_npc_controller()
	if controller and controller.has_method("mirar_hacia_direccion"):
		controller.call("mirar_hacia_direccion", direction)


## Establece una variable temporal
func set_variable(name: String, value: Variant) -> void:
	variables[name] = value


## Obtiene una variable temporal
func get_variable(name: String, default_value: Variant = null) -> Variant:
	return variables.get(name, default_value)


func set_global_flag(name: String, value: Variant) -> void:
	global_flags[name] = value


func get_global_flag(name: String, default_value: Variant = false) -> Variant:
	return global_flags.get(name, default_value)


func find_npc_by_id(npc_id: StringName) -> CharacterController:
	if npc and get_npc_data() and get_npc_data().npc_id == npc_id:
		return npc as CharacterController
	var tree: SceneTree = null
	if npc:
		tree = npc.get_tree()
	elif player:
		tree = player.get_tree()
	if tree:
		for candidate: Node in tree.get_nodes_in_group("NPC"):
			var controller: CharacterController = candidate as CharacterController
			if controller and controller.character_data is CharacterNpc:
				if (controller.character_data as CharacterNpc).npc_id == npc_id:
					return controller
	return null


func find_character_by_id(character_id: StringName) -> CharacterController:
	if player and player.character_data is CharacterPlayer:
		if (player.character_data as CharacterPlayer).PLAYER_ID == character_id:
			return player as CharacterController
	return find_npc_by_id(character_id)


func complete_async() -> void:
	if runner:
		runner.on_async_complete()
