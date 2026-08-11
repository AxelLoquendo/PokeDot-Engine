@tool
extends ScriptCommand
class_name ScriptCmdWarp

## Teletransporta al jugador o NPC a otra posición/mapa

enum WarpTarget {
	PLAYER,
	NPC,
	BOTH
}

@export var target: WarpTarget = WarpTarget.PLAYER
@export var target_map: String = ""  ## Nombre del mapa destino (vacío = mismo mapa)
@export var target_tile: Vector2i = Vector2i.ZERO
@export var spawn_direction: Vector2i = Vector2i(0, -1)  ## Dirección al aparecer
@export var fade_duration: float = 0.5  ## Duración del efecto de desvanecimiento


func execute(context: ScriptExecutionContext) -> bool:
	var targets_to_warp: Array[Node2D] = []
	
	if target == WarpTarget.PLAYER or target == WarpTarget.BOTH:
		if context.player:
			targets_to_warp.append(context.player)
	
	if target == WarpTarget.NPC or target == WarpTarget.BOTH:
		if context.npc:
			targets_to_warp.append(context.npc)
	
	if targets_to_warp.is_empty():
		return true
	
	# Ejecutar teletransporte
	for entity: Node2D in targets_to_warp:
		_warp_entity(entity, target_map, target_tile, spawn_direction)
	
	return true


func _warp_entity(entity: Node2D, map_name: String, tile: Vector2i, direction: Vector2i) -> void:
	if map_name != "":
		# Cambiar de mapa - NO IMPLEMENTADO AUN
		push_warning("ScriptCmdWarp: cambio de mapa aun no implementado")
	else:
		# Mover en el mismo mapa
		entity.position = Vector2(float(tile.x) * 16.0, float(tile.y) * 16.0)  ## Asumiendo tiles de 16px
		
		# Mirar hacia la dirección si el método existe
		if entity.has_method("mirar_hacia_posicion"):
			entity.call("mirar_hacia_posicion", Vector2(direction) * 16.0 + entity.global_position)


func get_display_text() -> String:
	var target_names: Array[String] = ["Jugador", "NPC", "Ambos"]
	var map_info: String = "mismo mapa" if target_map == "" else ("mapa: %s" % target_map)
	return "🌀 Teletransportar %s a %s (%d, %d)" % [target_names[target], map_info, target_tile.x, target_tile.y]
