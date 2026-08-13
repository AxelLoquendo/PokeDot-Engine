@tool
extends ScriptCommand
class_name ScriptCmdReturn

## Termina inmediatamente el script actual. Útil para salir de una rama.
func execute(context: ScriptExecutionContext) -> bool:
	if context.runner:
		context.runner.end_script()
	return true
