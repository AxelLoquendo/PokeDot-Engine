@tool
extends ScriptCommand
class_name ScriptCmdCompare

## compare flag FLAG_X == true etiqueta
## compare variable contador >= 3 etiqueta
## compare choice last_choice == 0 etiqueta
@export var source: String = "variable"
@export var key: String = ""
@export var operator: String = "=="
@export var expected: String = ""
@export var target_label: String = ""

func execute(context: ScriptExecutionContext) -> bool:
	var value: Variant = context.get_global_flag(key, false) if source == "flag" else context.get_variable(key, "")
	if _matches(value) and context.runner:
		context.runner.jump_to_label(target_label)
	return true

func _matches(value: Variant) -> bool:
	if expected.is_valid_float() and str(value).is_valid_float():
		var left: float = float(value)
		var right: float = float(expected)
		match operator:
			"==": return left == right
			"!=": return left != right
			">": return left > right
			">=": return left >= right
			"<": return left < right
			"<=": return left <= right
	var left_text: String = str(value).to_lower()
	var right_text: String = expected.to_lower()
	return left_text == right_text if operator == "==" else left_text != right_text if operator == "!=" else false
