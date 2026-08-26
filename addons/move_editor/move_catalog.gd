@tool
extends RefCounted

## Presentation helpers shared by the move dock and form. Enum values always
## come from the project's scripts; this class never maintains a second ID map.
class_name MoveEditorCatalog

var move_ids: Array[Dictionary] = []
var loaded: bool = false

func load_all() -> void:
	move_ids = enum_pairs(Moves.MoveId)
	loaded = true

func reload() -> void:
	loaded = false
	load_all()

func move_label(data: MoveData) -> String:
	if data == null:
		return "[?] UNKNOWN"
	return "[%d] %s" % [int(data.move_id), data.move_name if not data.move_name.is_empty() else "UNKNOWN"]

func enum_label(enum_name: String, key: String) -> String:
	var clean: String = key
	if enum_name == "MoveId":
		clean = clean.trim_prefix("MOVE_")
	elif enum_name == "Type":
		clean = clean.trim_prefix("TYPE_")
	elif enum_name == "DamageCategory":
		clean = clean
	else:
		clean = clean.trim_prefix("EFFECT_").trim_prefix("MOVE_EFFECT_").trim_prefix("Z_EFFECT_").trim_prefix("TARGET_")
	return clean.replace("_", " ").capitalize()

func enum_pairs(enum_dictionary: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var keys: Array = enum_dictionary.keys()
	var values: Array = enum_dictionary.values()
	for i: int in range(min(keys.size(), values.size())):
		result.append({"key": str(keys[i]), "value": int(values[i])})
	return result

func make_slug(value: String) -> String:
	var result: String = value.to_lower().strip_edges()
	result = result.replace(" ", "_").replace("-", "_")
	var clean: String = ""
	for character: String in result:
		if character.is_valid_identifier() or character == "_":
			clean += character
	return clean if not clean.is_empty() else "move"
