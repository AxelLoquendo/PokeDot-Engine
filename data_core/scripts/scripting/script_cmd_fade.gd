@tool
extends ScriptCommand
class_name ScriptCmdFade

@export var fade_out: bool = true
@export_range(0.05, 5.0, 0.05) var duration: float = 0.5

func execute(context: ScriptExecutionContext) -> bool:
	context.is_waiting = true
	var finished: Signal = TransicionManager.fade_out(duration) if fade_out else TransicionManager.fade_in(duration)
	finished.connect(context.complete_async, CONNECT_ONE_SHOT)
	return false
