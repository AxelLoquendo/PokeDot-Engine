## Representa un script de efecto ya parseado.
## Contiene bloques indexados por nombre de evento (on_hit, on_switch_in, etc.).
class_name EffectScript
extends RefCounted

## event_name → Array de EffectCommand
var blocks: Dictionary = {}

## Ruta de origen (para errores)
var source_path: String = ""


func has_block(event_name: String) -> bool:
	return blocks.has(event_name) and not (blocks[event_name] as Array).is_empty()


func get_block(event_name: String) -> Array:
	if blocks.has(event_name):
		return blocks[event_name] as Array
	return []


## Ejecuta todos los comandos de un bloque de evento.
## Devuelve true si se ejecutó algo.
func run(event_name: String, ctx: EffectContext) -> bool:
	var cmds: Array = get_block(event_name)
	if cmds.is_empty():
		return false

	EffectRunner.run_block(cmds, ctx)
	return true
