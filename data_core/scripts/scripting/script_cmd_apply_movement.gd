@tool
extends ScriptCommand
class_name ScriptCmdApplyMovement

## Temporary, explicit command list. Unlike CharacterNpc's autonomous loop this
## list runs once and completes. Every command resolves to one MovementAction.
@export var target_id: StringName
@export_multiline var movement_script: String = ""

func execute(context: ScriptExecutionContext) -> bool:
	var target: CharacterController = context.find_character_by_id(target_id)
	if not target: return true
	context.is_waiting = true
	_run_movement(target, context)
	return false

func _run_movement(target: CharacterController, context: ScriptExecutionContext) -> void:
	var previous_event_state: bool = target.ejecutando_evento
	target.ejecutando_evento = true
	
	for instruction: String in movement_script.split(";"):
		var trimmed: String = instruction.strip_edges()
		if trimmed.is_empty(): continue
		
		# Extraemos si hay un número de pasos al final de la instrucción (ej: "walk down 3")
		var parts: PackedStringArray = trimmed.split(" ", false)
		var repeticiones: int = 1
		
		# Si tiene 3 partes (comando, dirección, cantidad), el último podría ser el número de pasos
		if parts.size() >= 3 and parts[parts.size() - 1].is_valid_int():
			repeticiones = parts[parts.size() - 1].to_int()
			# Reconstruimos la instrucción quitándole el número del final para que el parser no se confunda
			var limpia: String = ""
			for i: int in range(parts.size() - 1):
				limpia += parts[i] + " "
			trimmed = limpia.strip_edges()
		
		var action: Dictionary = _parse_instruction(trimmed)
		if not action.is_empty():
			# Ejecutamos la acción tantas veces como pasos se hayan especificado
			for paso: int in range(repeticiones):
				await MovementExecutor.execute_action(target, action)
				
	target.ejecutando_evento = previous_event_state
	context.complete_async()


func _parse_instruction(instruction: String) -> Dictionary:
	var parts: PackedStringArray = instruction.split(" ", false)
	if parts.is_empty(): return {}
	var name: String = parts[0].to_lower().replace("-", "_")
	var direction: Vector2 = MovementTypes.direction_from_text(parts[1]) if parts.size() > 1 else Vector2.ZERO
	var kind: MovementTypes.MovementAction
	match name:
		"face", "look": return {"kind": MovementTypes.MovementAction.FACE, "direction": direction}
		"turn", "rotate", "clockwise", "rotate_clockwise": return {"kind": MovementTypes.MovementAction.TURN_CLOCKWISE}
		"counterclockwise", "rotate_counterclockwise": return {"kind": MovementTypes.MovementAction.TURN_COUNTERCLOCKWISE}
		"walk": kind = MovementTypes.MovementAction.WALK
		"jog": kind = MovementTypes.MovementAction.JOG
		"run": kind = MovementTypes.MovementAction.RUN
		"walk_in_place", "jog_in_place", "run_in_place", "slowly_in_place":
			return {"kind": MovementTypes.MovementAction.WALK_IN_PLACE, "mode": name}
		"copy_player": return {"kind": MovementTypes.MovementAction.COPY_PLAYER}
		"follow_player": return {"kind": MovementTypes.MovementAction.FOLLOW_PLAYER}
		"hide", "invisible": return {"kind": MovementTypes.MovementAction.HIDE}
		"show": return {"kind": MovementTypes.MovementAction.SHOW}
		"tree_disguise": return {"kind": MovementTypes.MovementAction.TREE_DISGUISE}
		"mountain_disguise": return {"kind": MovementTypes.MovementAction.MOUNTAIN_DISGUISE}
		"buried": return {"kind": MovementTypes.MovementAction.BURIED}
		"berry_tree_growth", "berry_growth": return {"kind": MovementTypes.MovementAction.BERRY_TREE_GROWTH}
		"wait": return {"kind": MovementTypes.MovementAction.WAIT, "seconds": float(parts[1]) if parts.size() > 1 and parts[1].is_valid_float() else 0.1}
		_: return {}
	# ApplyMovement is an explicit list: one instruction is one atomic action.
	# Repeat commands in the list when multiple steps are required.
	return {"kind": kind, "direction": direction, "mode": name}
