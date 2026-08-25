@tool
extends RefCounted

class_name SpeciesEnumManager

const SPECIES_SCRIPT_PATH: String = "res://data_core/pokemon/species.gd"
const CUSTOM_MARKER_TEXT: String = "Add any custom species between here and SPECIES_CUSTOM_END"

func get_next_custom_id(current_species: Array[PokemonDataStruct]) -> int:
	var content: String = _read_species_script()
	var candidate: int = int(Species.SpeciesID.SPECIES_CUSTOM_START) + 1
	for data: PokemonDataStruct in current_species:
		if data != null:
			candidate = maxi(candidate, int(data.species_id) + 1)

	while _numeric_id_is_reserved(content, candidate):
		candidate += 1
	return candidate

func register_custom_species(display_name: String, species_id: int) -> Error:
	var content: String = _read_species_script()
	if content.is_empty():
		return ERR_FILE_NOT_FOUND

	var enum_name: String = _make_enum_name(display_name)
	if enum_name.is_empty():
		return ERR_INVALID_PARAMETER
	if _enum_name_exists(content, enum_name):
		return ERR_ALREADY_EXISTS
	if _numeric_id_is_reserved(content, species_id):
		return ERR_ALREADY_EXISTS

	var lines: PackedStringArray = content.split("\n")
	var marker_index: int = -1
	for index: int in range(lines.size()):
		if lines[index].contains(CUSTOM_MARKER_TEXT):
			marker_index = index
			break
	if marker_index < 0:
		return ERR_DOES_NOT_EXIST

	lines.insert(marker_index, "\tSPECIES_%s = %d," % [enum_name, species_id])
	content = "\n".join(lines)

	return _write_species_script(content)

func unregister_custom_species(display_name: String, species_id: int) -> Error:
	var content: String = _read_species_script()
	var enum_name: String = _make_enum_name(display_name)
	var expected_line: String = "SPECIES_%s = %d," % [enum_name, species_id]
	var lines: PackedStringArray = content.split("\n")
	var found: bool = false
	for index: int in range(lines.size()):
		if lines[index].strip_edges() == expected_line:
			lines.remove_at(index)
			found = true
			break
	if not found:
		return ERR_DOES_NOT_EXIST
	return _write_species_script("\n".join(lines))

func _read_species_script() -> String:
	if not FileAccess.file_exists(SPECIES_SCRIPT_PATH):
		return ""
	return FileAccess.get_file_as_string(SPECIES_SCRIPT_PATH)

func _write_species_script(content: String) -> Error:
	var file: FileAccess = FileAccess.open(SPECIES_SCRIPT_PATH, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_OPEN
	file.store_string(content)
	file.close()
	return OK

func _enum_name_exists(content: String, enum_name: String) -> bool:
	return content.contains("SPECIES_%s =" % enum_name)

func _numeric_id_is_reserved(content: String, species_id: int) -> bool:
	var expected: String = "= %d," % species_id
	for line: String in content.split("\n"):
		if line.strip_edges().ends_with(expected):
			return true
	return false

func _make_enum_name(display_name: String) -> String:
	var result: String = ""
	var previous_was_separator: bool = false
	for character: String in display_name.to_upper():
		var code: int = character.unicode_at(0)
		var valid: bool = (code >= 65 and code <= 90) or (code >= 48 and code <= 57)
		if valid:
			result += character
			previous_was_separator = false
		elif not previous_was_separator and not result.is_empty():
			result += "_"
			previous_was_separator = true
	return result.trim_suffix("_")
