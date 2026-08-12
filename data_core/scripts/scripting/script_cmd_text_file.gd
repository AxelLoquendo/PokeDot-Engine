@tool
extends ScriptCommand
class_name ScriptCmdTextFile

## Comando para cargar y ejecutar scripts desde archivos de texto
## Similar al sistema de scripting de Pokémon (pokeemerald-expansion)
## Uso: El NPC carga un archivo .txt con comandos de script

@export_file("*.txt") var script_file_path: String = ""  ## Ruta al archivo de script
@export var execute_on_start: bool = true  ## Ejecutar automáticamente al iniciar

var parser: ScriptTextParser = null
var loaded_commands: Array = []


func get_inline_commands(context: ScriptExecutionContext) -> Array[ScriptCommand]:
	if script_file_path == "":
		push_warning("ScriptCmdTextFile: no se especifico archivo de script")
		return []

	if loaded_commands.is_empty() and not _load_script_file():
		return []

	return _convert_parsed_commands(loaded_commands, context)


func execute(_context: ScriptExecutionContext) -> bool:
	return true


func _legacy_execute(context: ScriptExecutionContext) -> bool:

	if script_file_path == "":
		push_warning("ScriptCmdTextFile: No se especificó archivo de script")
		return true
	
	# Cargar y parsear el archivo si no está cargado
	if loaded_commands.is_empty():
		if not _load_script_file():
			return true  # Error, continuar con siguiente comando
	
	# Ejecutar los comandos cargados
	if not loaded_commands.is_empty():
		var runner: Node = context.npc.get_node_or_null("ScriptRunner") if context.npc else null
		if runner and runner.has_method("start_script"):
			# Convertir comandos parseados a ScriptCommand objects
			var commands_to_execute: Array[ScriptCommand] = _convert_parsed_commands(loaded_commands, context)
			if not commands_to_execute.is_empty():
				runner.call("start_script", commands_to_execute, context.npc, context.player, context.map)
	
	return true


func _load_script_file() -> bool:
	parser = ScriptTextParser.new()
	loaded_commands = parser.load_script_file(script_file_path)
	
	if parser.has_error:
		push_error("ScriptCmdTextFile: Error al cargar %s: %s" % [script_file_path, parser.error_message])
		return false
	
	if loaded_commands.is_empty():
		push_warning("ScriptCmdTextFile: Archivo vacío o sin comandos válidos: %s" % script_file_path)
		return false
	
	print("ScriptCmdTextFile: Script cargado exitosamente: %s (%d comandos)" % [script_file_path, loaded_commands.size()])
	return true


func _convert_parsed_commands(parsed: Array, context: ScriptExecutionContext) -> Array[ScriptCommand]:
	var commands: Array[ScriptCommand] = []
	var pending_texts: Array[String] = []

	for cmd_dict: Dictionary[String, Variant] in parsed:
		var command_name: String = cmd_dict.get("command", "") as String
		if command_name == "text":
			var args: Array[String] = cmd_dict.get("args", []) as Array[String]
			pending_texts.append(" ".join(args))
			continue

		_append_text_command(commands, pending_texts)
		pending_texts.clear()

		if command_name == "end":
			break

		var command: ScriptCommand = _create_command_from_dict(cmd_dict, context)
		if command:
			commands.append(command)

	_append_text_command(commands, pending_texts)
	return commands


func _append_text_command(commands: Array[ScriptCommand], texts: Array[String]) -> void:
	if texts.is_empty():
		return
	var command: ScriptCmdText = ScriptCmdText.new()
	command.message = texts[0]
	command.messages = texts.duplicate()
	commands.append(command)


func _create_command_from_dict(cmd_dict: Dictionary[String, Variant], _context: ScriptExecutionContext) -> ScriptCommand:
	var command_name: String = cmd_dict.get("command", "") as String
	var args: Array[String] = cmd_dict.get("args", []) as Array[String]
	
	match command_name:
		"text":
			var cmd: ScriptCmdText = ScriptCmdText.new()
			if not args.is_empty():
				cmd.message = " ".join(args)
			return cmd
		
		"waitbutton":
			var cmd: ScriptCmdWait = ScriptCmdWait.new()
			cmd.wait_for_input = true
			cmd.input_action = "buttonA"
			return cmd
		
		"setflag":
			var cmd: ScriptCmdSetFlag = ScriptCmdSetFlag.new()
			if not args.is_empty():
				cmd.flag_name = args[0]
			cmd.value = true
			return cmd
		
		"clearflag":
			var cmd: ScriptCmdSetFlag = ScriptCmdSetFlag.new()
			if not args.is_empty():
				cmd.flag_name = args[0]
			cmd.value = false
			return cmd
		
		"warp":
			var cmd: ScriptCmdWarp = ScriptCmdWarp.new()
			if args.size() >= 3:
				cmd.target_map = args[0]
				var pos_x: int = int(args[1]) if args[1].is_valid_int() else 0
				var pos_y: int = int(args[2]) if args[2].is_valid_int() else 0
				cmd.target_tile = Vector2i(pos_x, pos_y)
			return cmd
		
		"giveitem":
			# Nota: ScriptCmdGiveItem no existe en los scripts proporcionados previamente.
			# Se deja como placeholder tipado. Deberás crear esta clase.
			var cmd: ScriptCmdGiveItem = ScriptCmdGiveItem.new()
			if not args.is_empty():
				cmd.item_id = args[0]
			if args.size() > 1 and args[1].is_valid_int():
				cmd.amount = int(args[1])
			return cmd
		
		"sound":
			var cmd: ScriptCmdSound = ScriptCmdSound.new()
			if not args.is_empty():
				cmd.sound_path = args[0]
			return cmd
		
		"end":
			# Fin del script
			return null
		
		_:
			push_warning("ScriptCmdTextFile: Comando no implementado '%s'" % command_name)
			return null


func get_display_text() -> String:
	if script_file_path != "":
		var file_name: String = script_file_path.get_file()
		return "📄 Script: " + file_name
	return "📄 Script: (sin archivo)"
