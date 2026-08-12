@tool
extends ScriptCommand
class_name ScriptCmdWait

## Pausa la ejecución del script por un tiempo determinado

@export_range(0.1, 10.0, 0.1) var seconds: float = 1.0
@export var wait_for_input: bool = false  ## Esperar a que el jugador presione un botón
@export var input_action: String = "interact"  ## Acción de input para esperar


func execute(context: ScriptExecutionContext) -> bool:
	var tree: SceneTree = context.npc.get_tree() if context.npc else Engine.get_main_loop() as SceneTree
	
	if wait_for_input:
		context.is_waiting = true
		tree.process_frame.connect(_check_input.bind(context), CONNECT_ONE_SHOT)
		return false
	else:
		tree.create_timer(seconds).timeout.connect(_on_wait_finished.bind(context))
		context.is_waiting = true
		return false


func _legacy_on_wait_finished(context: ScriptExecutionContext) -> void:
	context.complete_async()
	context.is_waiting = false
	# Notificar al ScriptRunner que continúe
	if context.npc and context.npc.has_node("ScriptRunner"):
		var runner: Node = context.npc.get_node("ScriptRunner")
		if runner.has_method("on_async_complete"):
			runner.call("on_async_complete")


func _on_wait_finished(context: ScriptExecutionContext) -> void:
	context.complete_async()


func _check_input(context: ScriptExecutionContext) -> void:
	if Input.is_action_just_pressed(input_action):
		_on_wait_finished(context)
	else:
		var tree: SceneTree = context.npc.get_tree() if context.npc else Engine.get_main_loop() as SceneTree
		tree.process_frame.connect(_check_input.bind(context), CONNECT_ONE_SHOT)


func get_display_text() -> String:
	if wait_for_input:
		return "⏸️ Esperar Input: %s" % input_action
	else:
		return "⏸️ Esperar: %.1fs" % seconds
