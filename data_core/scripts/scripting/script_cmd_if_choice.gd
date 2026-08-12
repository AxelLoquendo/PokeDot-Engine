@tool
extends ScriptCommand
class_name ScriptCmdIfChoice

## Salta a una etiqueta si coincide la elección más reciente.
@export var expected_choice: String = "0"
@export var target_label: String = ""
@export var choice_variable: String = "last_choice"

func execute(context: ScriptExecutionContext) -> bool:
	if str(context.get_variable(choice_variable, "")) == expected_choice:
		context.runner.jump_to_label(target_label)
	return true
