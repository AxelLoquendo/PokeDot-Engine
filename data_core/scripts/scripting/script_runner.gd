extends Node
class_name ScriptRunner

## Ejecutor de scripts para NPCs
## Maneja la ejecución secuencial de comandos de script

var commands: Array[ScriptCommand] = []
var context: ScriptExecutionContext = null
var is_running: bool = false
var current_index: int = 0

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
	context = ScriptExecutionContext.new(npc_node, player_node, map_node)
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
	
	var completed: bool = command.execute(context)
	command_executed.emit(command)
	
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
	if context:
		context.is_waiting = false
		current_index += 1
		_execute_current_command()


func _finish_script() -> void:
	is_running = false
	set_process(false)
	script_finished.emit()
