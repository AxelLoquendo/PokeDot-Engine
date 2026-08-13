@tool
extends Resource
class_name MapScriptEntry

## Una entrada equivalente a map_script / map_script_2 de pokeemerald.
enum Trigger {
	ON_TRANSITION,
	ON_FRAME_TABLE,
	ON_LOAD,
	ON_RESUME,
	ON_RETURN_TO_FIELD,
	ON_DIVE_WARP,
	ON_WARP_INTO_MAP_TABLE,
}

@export var trigger: Trigger = Trigger.ON_LOAD
@export_file("*.txt") var script_file: String = ""
@export_group("Condición (map_script_2)")
@export var condition_flag: StringName = &""
@export var expected_value: String = "true"


func condition_matches() -> bool:
	if condition_flag.is_empty():
		return true
	return str(ScriptExecutionContext.global_flags.get(condition_flag, false)).to_lower() == expected_value.to_lower()
