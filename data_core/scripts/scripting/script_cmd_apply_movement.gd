@tool
extends ScriptCommand
class_name ScriptCmdApplyMovement

## Ejemplo: applymovement npc_guardia "walk left 2; face down; wait 0.5"
@export var target_id: StringName
@export_multiline var movement_script: String = ""

func execute(context: ScriptExecutionContext) -> bool:
	var target: CharacterController = context.find_character_by_id(target_id)
	if not target:
		push_warning("ScriptCmdApplyMovement: no se encontró el NPC '%s'" % target_id)
		return true
	context.is_waiting = true
	_run_movement(target, context)
	return false


func _run_movement(target: CharacterController, context: ScriptExecutionContext) -> void:
	var previous_event_state: bool = target.ejecutando_evento
	target.ejecutando_evento = true
	for instruction: String in movement_script.split(";"):
		var parts: PackedStringArray = instruction.strip_edges().split(" ", false)
		if parts.is_empty():
			continue
		var action: String = parts[0].to_lower()
		if action == "face" and parts.size() > 1:
			_face(target, parts[1])
		elif action == "walk" and parts.size() > 1:
			var steps: int = int(parts[2]) if parts.size() > 2 and parts[2].is_valid_int() else 1
			var direction: Vector2 = _direction(parts[1])
			for step: int in range(steps):
				if direction != Vector2.ZERO:
					await _walk_one_step(target, direction)
		elif action == "wait" and parts.size() > 1 and parts[1].is_valid_float():
			await target.get_tree().create_timer(float(parts[1])).timeout
	target.ejecutando_evento = previous_event_state
	context.complete_async()


func _walk_one_step(target: CharacterController, direction: Vector2) -> void:
	target.cancelar_movimiento()
	var old_tile: Vector2i = target.casilla_actual
	var new_tile: Vector2i = old_tile + Vector2i(direction)
	var destination: Vector2 = target.position + direction * target.TILE_SIZE

	EventObjects.liberar_casilla(old_tile)
	EventObjects.liberar_reserva(old_tile)
	EventObjects.reservar_casilla(new_tile, target)
	target.input_direction = direction
	target.is_moving = false
	target.reproducir_paso()

	var duration: float = 1.0 / maxf(target.obtener_velocidad_movimiento(), 0.1)
	var tween: Tween = target.create_tween()
	tween.tween_property(target, "position", destination, duration)
	await tween.finished

	target.position = target.snap_to_grid(destination)
	target.casilla_actual = new_tile
	target.casilla_reservada = new_tile
	EventObjects.liberar_reserva(new_tile)
	EventObjects.registrar_casilla(new_tile, target)
	target.reproducir_idle()


func _face(target: CharacterController, value: String) -> void:
	target.mirar_hacia_posicion(target.global_position + _direction(value) * target.TILE_SIZE)
	target.reproducir_idle()


func _direction(value: String) -> Vector2:
	match value.to_lower():
		"up", "arriba": return Vector2.UP
		"down", "abajo": return Vector2.DOWN
		"left", "izquierda": return Vector2.LEFT
		"right", "derecha": return Vector2.RIGHT
	return Vector2.ZERO
