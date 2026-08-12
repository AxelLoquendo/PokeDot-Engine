@tool
extends ScriptCommand
class_name ScriptCmdGoto

@export var target_label: String = ""

func execute(context: ScriptExecutionContext) -> bool:
	if target_label.is_empty():
		push_warning("ScriptCmdGoto: falta la etiqueta destino")
		return true
	context.runner.jump_to_label(target_label)
	return true
