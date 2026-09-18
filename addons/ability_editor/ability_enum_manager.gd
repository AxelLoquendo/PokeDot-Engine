@tool
extends RefCounted

class_name AbilityEnumManager

const ABILITY_SCRIPT_PATH: String = "res://data_core/ability/ability.gd"
const COUNT_MARKER: String = "COUNT ="

func get_next_id() -> int:
	var content: String = _read_script()
	var candidate: int = 1
	for line: String in content.split("\n"):
		var parsed_id: int = _line_id(line)
		if parsed_id >= candidate:
			candidate = parsed_id + 1
	while _id_is_reserved(content, candidate):
		candidate += 1
	return candidate

func register_custom_ability(name_key: String, ability_id: int) -> Error:
	var content: String = _read_script()
	if content.is_empty() or ability_id <= 0:
		return ERR_INVALID_PARAMETER
	if _id_is_reserved(content, ability_id):
		return ERR_ALREADY_EXISTS
	var enum_name: String = _make_enum_name(name_key)
	if enum_name.is_empty() or _enum_name_exists(content, enum_name):
		return ERR_ALREADY_EXISTS
	var lines: PackedStringArray = content.split("\n")
	var count_index: int = -1
	var current_count: int = 0
	for index: int in range(lines.size()):
		if lines[index].strip_edges().begins_with(COUNT_MARKER):
			count_index = index
			current_count = _line_id(lines[index])
			break
	if count_index < 0:
		return ERR_DOES_NOT_EXIST
	lines.insert(count_index, "\t%s = %d," % [enum_name, ability_id])
	if ability_id >= current_count:
		lines[count_index + 1] = "\tCOUNT = %d," % (ability_id + 1)
	return _write_script("\n".join(lines))

func unregister_custom_ability(name_key: String, ability_id: int) -> Error:
	var content: String = _read_script()
	var enum_name: String = _make_enum_name(name_key)
	var lines: PackedStringArray = content.split("\n")
	var removed: bool = false
	for index: int in range(lines.size()):
		if lines[index].strip_edges() == "%s = %d," % [enum_name, ability_id]:
			lines.remove_at(index)
			removed = true
			break
	if not removed:
		return ERR_DOES_NOT_EXIST
	return _write_script("\n".join(lines))

func _read_script() -> String:
	if not FileAccess.file_exists(ABILITY_SCRIPT_PATH):
		return ""
	return FileAccess.get_file_as_string(ABILITY_SCRIPT_PATH)

func _write_script(content: String) -> Error:
	var file: FileAccess = FileAccess.open(ABILITY_SCRIPT_PATH, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_string(content)
	file.close()
	return OK

func _line_id(line: String) -> int:
	var equal_index: int = line.find("=")
	if equal_index < 0:
		return -1
	var value_text: String = line.substr(equal_index + 1).strip_edges().trim_suffix(",")
	return int(value_text) if value_text.is_valid_int() else -1

func _id_is_reserved(content: String, ability_id: int) -> bool:
	for line: String in content.split("\n"):
		if _line_id(line) == ability_id:
			return true
	return false

func _enum_name_exists(content: String, enum_name: String) -> bool:
	return content.contains("\t%s =" % enum_name)

func _make_enum_name(raw_name: String) -> String:
	var result: String = ""
	var previous_separator: bool = false
	for character: String in raw_name.to_upper():
		var code: int = character.unicode_at(0)
		var valid: bool = (code >= 65 and code <= 90) or (code >= 48 and code <= 57)
		if valid:
			result += character
			previous_separator = false
		elif not previous_separator and not result.is_empty():
			result += "_"
			previous_separator = true
	return result.trim_suffix("_")
