## Parsea un archivo .txt de efecto y devuelve un EffectScript.
## Sintaxis inspirada en los scripts de campo del proyecto.
class_name EffectParser
extends RefCounted

## Registro de fábricas de comandos: nombre → Callable
static var _command_factories: Dictionary = {}


static func register_command(name: String, factory: Callable) -> void:
	_command_factories[name.to_lower()] = factory


static func parse_file(path: String) -> EffectScript:
	var script: EffectScript = EffectScript.new()
	script.source_path = path

	if not FileAccess.file_exists(path):
		push_warning("EffectParser: no existe '%s'" % path)
		return script

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("EffectParser: no se pudo abrir '%s'" % path)
		return script

	var text: String = file.get_as_text()
	file.close()
	return parse_text(text, path)


static func parse_text(text: String, source_path: String = "") -> EffectScript:
	var script: EffectScript = EffectScript.new()
	script.source_path = source_path

	var current_block: String = ""
	var current_commands: Array = []

	var lines: PackedStringArray = text.split("\n")
	for line_num: int in range(lines.size()):
		var raw: String = lines[line_num]
		var line: String = raw.strip_edges()

		if line.is_empty() or line.begins_with("#") or line.begins_with("//"):
			continue

		if line.ends_with(":"):
			if not current_block.is_empty():
				script.blocks[current_block] = current_commands
			current_block = line.substr(0, line.length() - 1).strip_edges().to_lower()
			current_commands = []
			continue

		if current_block.is_empty():
			push_warning("EffectParser [%s:%d]: comando fuera de bloque: '%s'" % [source_path, line_num + 1, line])
			continue

		var parts: PackedStringArray = _tokenize(line)
		if parts.is_empty():
			continue

		var cmd_name: String = parts[0].to_lower()
		var cmd_args: PackedStringArray = parts.slice(1)

		var cmd: EffectCommand = _create_command(cmd_name, cmd_args)
		if cmd != null:
			current_commands.append(cmd)
		else:
			push_warning("EffectParser [%s:%d]: comando desconocido '%s'" % [source_path, line_num + 1, cmd_name])

	if not current_block.is_empty():
		script.blocks[current_block] = current_commands

	return script


static func _tokenize(line: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var current: String = ""
	var in_quotes: bool = false

	for i: int in range(line.length()):
		var c: String = line[i]
		if c == "\"":
			in_quotes = not in_quotes
			continue
		if c == " " and not in_quotes:
			if not current.is_empty():
				result.append(current)
				current = ""
			continue
		current += c

	if not current.is_empty():
		result.append(current)
	return result


static func _create_command(name: String, args: PackedStringArray) -> EffectCommand:
	if _command_factories.has(name):
		var factory: Callable = _command_factories[name] as Callable
		return factory.call(args) as EffectCommand
	return EffectCommand.new(name, args)
