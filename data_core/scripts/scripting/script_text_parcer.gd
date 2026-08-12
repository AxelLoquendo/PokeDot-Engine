@tool
extends Resource
class_name ScriptTextParser

## Parser de scripts basados en texto para NPCs
## Similar al sistema de scripting de pokeemerald-expansion
## Permite definir scripts en archivos .txt con comandos simples

const COMANDOS_VALIDOS: Array[String] = [
	"text", "waitbutton", "setflag", "clearflag", "warp", "giveitem", "sound", "end"
]

var parsed_commands: Array = []
var error_message: String = ""
var has_error: bool = false


## Parsea un script desde un string de texto
func parse_script(script_text: String) -> Array:
	parsed_commands.clear()
	has_error = false
	error_message = ""
	
	var lines: PackedStringArray = script_text.split("\n")
	var line_number: int = 0
	
	for raw_line: String in lines:
		line_number += 1
		var line: String = raw_line.strip_edges()
		
		# Ignorar líneas vacías y comentarios
		if line.is_empty() or line.begins_with("#") or line.begins_with("//"):
			continue
		
		var command_dict: Dictionary[String, Variant] = _parse_line(line, line_number)
		if has_error:
			return []
		
		if not command_dict.is_empty():
			parsed_commands.append(command_dict)
			if command_dict["command"] == "end":
				break
	
	return parsed_commands


## Parsea una línea individual del script
func _parse_line(line: String, line_number: int) -> Dictionary[String, Variant]:
	var parts: PackedStringArray = line.split(" ", false)
	if parts.is_empty():
		return {} as Dictionary[String, Variant]
	
	var command_name: String = parts[0].to_lower()
	var args: Array[String] = []
	for i: int in range(1, parts.size()):
		args.append(parts[i])
	
	# Validar comando
	if command_name not in COMANDOS_VALIDOS:
		has_error = true
		error_message = "Línea %d: Comando desconocido '%s'" % [line_number, command_name]
		push_error(error_message)
		return {} as Dictionary[String, Variant]
	
	var command_dict: Dictionary[String, Variant] = {
		"command": command_name,
		"args": args,
		"line": line_number
	}
	
	return command_dict


## Carga y parsea un archivo de script desde una ruta
func load_script_file(file_path: String) -> Array:
	if not FileAccess.file_exists(file_path):
		has_error = true
		error_message = "Archivo no encontrado: %s" % file_path
		push_error(error_message)
		return []
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		has_error = true
		error_message = "No se pudo abrir el archivo: %s" % file_path
		push_error(error_message)
		return []
	
	var script_text: String = file.get_as_text()
	file.close()
	
	return parse_script(script_text)


## Obtiene información de depuración
func get_debug_info() -> String:
	var info: String = "Comandos parseados: %d\n" % parsed_commands.size()
	for cmd: Dictionary[String, Variant] in parsed_commands:
		var cmd_name: String = cmd.get("command", "") as String
		var cmd_args: Variant = cmd.get("args", [])
		info += "  - %s: %s\n" % [cmd_name, str(cmd_args)]
	return info
