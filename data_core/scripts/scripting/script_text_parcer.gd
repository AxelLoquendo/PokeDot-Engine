@tool
extends Resource
class_name ScriptTextParser

## Parser de scripts basados en texto para NPCs
## Similar al sistema de scripting de pokeemerald-expansion
## Permite definir scripts en archivos .txt con comandos simples

const COMANDOS_VALIDOS: Array[String] = [
	"text",
	"multichoice",
	"label",
	"goto",
	"ifchoice",
	"ifflag",
	"compare",
	"applymovement",
	"weather",
	"fadeout",
	"fadein",
	"savegame",
	"waitbutton",
	"setflag",
	"clearflag",
	"moveplayer",
	"faceplayer",
	"lock",
	"release",
	"warp",
	"giveitem",
	"sound",
	"return",
	"end"
]


enum MsgboxType {
	NPC,        # 0: Lock + FacePlayer + Text + Release
	DEFAULT,    # 1: Solo texto (tú manejas lock/faceplayer)
	SIGN,       # 2: Texto estilo cartel
	YESNO,      # 3: Texto + Selección Sí/No
	AUTOCLOSE,  # 4: Texto que se cierra solo
	GETINPUT    # 5: Texto esperando input externo
}

# Diccionario para convertir strings del txt a Enums
const MSGBOX_MAP: Dictionary[String, MsgboxType] = {
	"MSGBOX_NPC": MsgboxType.NPC,
	"MSGBOX_DEFAULT": MsgboxType.DEFAULT,
	"MSGBOX_SIGN": MsgboxType.SIGN,
	"MSGBOX_YESNO": MsgboxType.YESNO,
	"MSGBOX_AUTOCLOSE": MsgboxType.AUTOCLOSE,
	"MSGBOX_GETINPUT": MsgboxType.GETINPUT,
}

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
func _parse_line_legacy(line: String, line_number: int) -> Dictionary[String, Variant]:
	var parts: PackedStringArray = line.split(" ", false)
	if parts.is_empty():
		return {} as Dictionary[String, Variant]
		
	var command_name: String = parts[0].to_lower()
	
	# Reconstruir el resto de la línea
	var args_text: String = ""
	if parts.size() > 1:
		args_text = line.substr(command_name.length()).strip_edges()
	
	var args: Array[String] = []
	
	# Lógica para argumentos (Manejo de comillas y tipo de msgbox)
	if args_text.begins_with("\""):
		# Buscamos el cierre de comillas
		var closing_quote_index: int = args_text.find("\"", 1)
		if closing_quote_index != -1:
			# Extraemos el texto entre comillas
			var text_content: String = args_text.substr(1, closing_quote_index - 1)
			args.append(text_content)
			
			# Verificamos si hay un segundo argumento (el tipo MSGBOX) después de las comillas
			var remainder: String = args_text.substr(closing_quote_index + 1).strip_edges()
			if not remainder.is_empty():
				# Si hay algo después (ej: MSGBOX_YESNO), lo agregamos como segundo argumento
				args.append(remainder)
		else:
			# Error de sintaxis: comilla abierta sin cerrar
			has_error = true
			error_message = "Línea %d: Comillas sin cerrar en '%s'" % [line_number, line]
			push_error(error_message)
			return {} as Dictionary[String, Variant]
	else:
		# Sin comillas: separar por espacios (texto simple o comandos sin argumentos complejos)
		var split_args: PackedStringArray = args_text.split(" ", false)
		for arg: String in split_args:
			args.append(arg)
	
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
	} as Dictionary[String, Variant]
	
	return command_dict

func _parse_line(line: String, line_number: int) -> Dictionary[String, Variant]:
	var separator: int = line.find(" ")
	var command_name: String = line if separator == -1 else line.left(separator)
	command_name = command_name.to_lower()
	var args_source: String = "" if separator == -1 else line.substr(separator + 1)
	var args: Array[String] = _tokenize_arguments(args_source, line_number)
	if has_error:
		return {} as Dictionary[String, Variant]
	if command_name not in COMANDOS_VALIDOS:
		has_error = true
		error_message = "Línea %d: comando desconocido '%s'" % [line_number, command_name]
		push_error(error_message)
		return {} as Dictionary[String, Variant]
	return {
		"command": command_name,
		"args": args,
		"line": line_number
	} as Dictionary[String, Variant]


func _tokenize_arguments(source: String, line_number: int) -> Array[String]:
	var args: Array[String] = []
	var current: String = ""
	var inside_quotes: bool = false
	for character: String in source:
		if character == "\"":
			inside_quotes = not inside_quotes
		elif (character == " " or character == "\t") and not inside_quotes:
			if not current.is_empty():
				args.append(current)
				current = ""
		else:
			current += character
	if inside_quotes:
		has_error = true
		error_message = "Línea %d: comillas sin cerrar" % line_number
		push_error(error_message)
		return []
	if not current.is_empty():
		args.append(current)
	return args


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
