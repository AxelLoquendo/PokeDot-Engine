@tool
extends ScriptCommand
class_name ScriptCmdLabel

## Marca una posición a la que goto o ifchoice pueden saltar.
@export var label_name: String = ""

func execute(_context: ScriptExecutionContext) -> bool:
	return true
