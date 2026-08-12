@tool
extends ScriptCommand
class_name ScriptCmdIfFlag

@export var flag_name: String = ""
@export var target_label: String = ""

func execute(context: ScriptExecutionContext) -> bool:
	if bool(context.get_global_flag(flag_name, false)):
		context.runner.jump_to_label(target_label)
	return true
