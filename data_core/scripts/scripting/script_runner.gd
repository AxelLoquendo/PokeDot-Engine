extends Node
class_name ScriptRunner

## Ejecutor de scripts para NPCs
## Maneja la ejecución secuencial de comandos de script

var commands: Array[ScriptCommand] = []
var context: ScriptExecutionContext = null
var is_running: bool = false
var current_index: int = 0
var labels: Dictionary[String, int] = {}

signal script_started()
signal script_finished()
signal command_executed(command: ScriptCommand)


func _ready() -> void:
	set_process(false)


## Inicia la ejecución de un script con los parámetros dados
func start_script(script_commands: Array[ScriptCommand], npc_node: Node2D = null, player_node: Node2D = null, map_node: Node = null) -> void:
	if is_running:
		push_warning("ScriptRunner: ya hay un script en ejecución")
		return
	
	commands = script_commands.duplicate()
	_rebuild_labels()
	context = ScriptExecutionContext.new(npc_node, player_node, map_node)
	context.runner = self
	current_index = 0
	is_running = true
	
	script_started.emit()
	set_process(true)
	
	# Ejecutar primer comando
	_execute_current_command()


## Detiene la ejecución del script actual
func stop_script() -> void:
	is_running = false
	set_process(false)
	commands.clear()
	context = null


## Finaliza el script desde un comando de texto (return/end).
func end_script() -> void:
	if is_running:
		_finish_script()


func _process(_delta: float) -> void:
	if not is_running or context == null:
		set_process(false)
		return
	
	if context.is_waiting:
		return
	
	_execute_current_command()


func _execute_current_command() -> void:
	if current_index >= commands.size():
		_finish_script()
		return
	
	var command: ScriptCommand = commands[current_index]
	
	if not command or not command.enabled:
		current_index += 1
		_execute_current_command()
		return
	
	var inline_commands: Array[ScriptCommand] = command.get_inline_commands(context)
	if not inline_commands.is_empty():
		commands.remove_at(current_index)
		for index: int in range(inline_commands.size() - 1, -1, -1):
			commands.insert(current_index, inline_commands[index])
		_rebuild_labels()
		_execute_current_command()
		return

	var completed: bool = command.execute(context)
	command_executed.emit(command)
	# Un comando como `return` puede finalizar el runner durante execute().
	if not is_running:
		return
	
	if completed:
		current_index += 1
		# Continuar ejecutando si no estamos esperando
		if not context.is_waiting:
			_execute_current_command()
	else:
		# Comando asíncrono - esperar a que se complete
		pass


## Llama cuando un diálogo o evento asíncrono ha terminado
func on_async_complete() -> void:
	if is_running and context and context.is_waiting:
		context.is_waiting = false
		current_index += 1
		_execute_current_command()


func jump_to_label(label_name: String) -> bool:
	if not labels.has(label_name):
		push_error("ScriptRunner: etiqueta no encontrada '%s'" % label_name)
		return false
	current_index = labels[label_name]
	return true


func _rebuild_labels() -> void:
	labels.clear()
	for index: int in range(commands.size()):
		var command: ScriptCommand = commands[index]
		if command is ScriptCmdLabel:
			labels[(command as ScriptCmdLabel).label_name] = index


func _finish_script() -> void:
	is_running = false
	set_process(false)
	script_finished.emit()
