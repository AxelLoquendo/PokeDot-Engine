## Clase base de un comando de efecto.
## Cada pieza del Lego hereda de esto.
class_name EffectCommand
extends RefCounted

## Nombre del comando (para debug y errores)
var command_name: String = ""

## Argumentos parseados del .txt
var args: PackedStringArray = []


func _init(p_name: String = "", p_args: PackedStringArray = []) -> void:
	command_name = p_name
	args = p_args


## Ejecuta el comando. Devuelve true si debe continuar, false para detener el bloque.
func execute(_ctx: EffectContext) -> bool:
	push_warning("EffectCommand '%s' no implementado" % command_name)
	return true


## Helpers de parseo de argumentos
func arg_string(index: int, default: String = "") -> String:
	if index < args.size():
		return args[index]
	return default


func arg_int(index: int, default: int = 0) -> int:
	if index < args.size() and args[index].is_valid_int():
		return args[index].to_int()
	return default


func arg_float(index: int, default: float = 0.0) -> float:
	if index < args.size() and args[index].is_valid_float():
		return args[index].to_float()
	return default


func has_arg(index: int) -> bool:
	return index < args.size()
