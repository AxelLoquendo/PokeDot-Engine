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
	var targets_to_warp = []
	
	if target == WarpTarget.PLAYER or target == WarpTarget.BOTH:
		if context.player:
			targets_to_warp.append(context.player)
	
	if target == WarpTarget.NPC or target == WarpTarget.BOTH:
		if context.npc:
			targets_to_warp.append(context.npc)
	
	if targets_to_warp.is_empty():
		return true
	
	# Aplicar efecto de fade si está configurado
	if fade_duration > 0:
		_apply_fade_effect(fade_duration / 2.0)
		await context.npc.get_tree().create_timer(fade_duration / 2.0).timeout
	
	# Ejecutar teletransporte
	for entity in targets_to_warp:
		_warp_entity(entity, target_map, target_tile, spawn_direction)
	
	if fade_duration > 0:
		await context.npc.get_tree().create_timer(fade_duration / 2.0).timeout
		_apply_fade_effect(-fade_duration / 2.0)  ## Fade in
	
	return true

func _warp_entity(entity: Node2D, map_name: String, tile: Vector2i, direction: Vector2i) -> void:
	if map_name != "":
		# Cambiar de mapa
		if MapManager.has_method("change_map"):
			MapManager.change_map(map_name, tile, direction)
	else:
		# Mover en el mismo mapa
		entity.position = Vector2(tile.x * 16, tile.y * 16)  ## Asumiendo tiles de 16px
		
		if entity.has_method("mirar_hacia_direccion"):
			entity.mirar_hacia_direccion(direction)

func _apply_fade_effect(duration: float) -> void:
	# Implementar efecto de fade usando CanvasLayer
	pass

func get_display_text() -> String:
	var target_names = ["Jugador", "NPC", "Ambos"]
	var map_info = "mismo mapa" if target_map == "" else "mapa: %s" % target_map
	return "🌀 Teletransportar %s a %s (%d, %d)" % [target_names[target], map_info, target_tile.x, target_tile.y]
