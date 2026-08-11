@tool
extends Resource
class_name ScriptCommand

## Clase base para todos los comandos de script
## Cada comando debe heredar de esta clase e implementar execute()

@export var enabled: bool = true
@export var comment: String = ""  ## Comentario opcional para documentación

## Ejecuta el comando
## Retorna true si el comando es síncrono (se completa inmediatamente)
## Retorna false si el comando es asíncrono (espera a un evento)
func execute(context: ScriptExecutionContext) -> bool:
	push_warning("ScriptCommand: execute() no implementado en la clase base")
	return true

## Dibuja información en el editor (opcional, para debugging visual)
func get_display_text() -> String:
	return comment if comment != "" else get_class()
