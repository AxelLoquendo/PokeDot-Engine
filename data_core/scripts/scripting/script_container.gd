@tool
extends Resource
class_name ScriptContainer

## Contenedor de scripts para NPCs
## Permite definir múltiples scripts que pueden ser asignados a un NPC

@export_group("Scripts")
@export var on_interact: Array[ScriptCommand] = []  ## Script al interactuar
@export var on_approach: Array[ScriptCommand] = []  ## Script al acercarse (opcional)
@export var on_sight: Array[ScriptCommand] = []  ## Script al ser visto (opcional)
@export var on_defeat: Array[ScriptCommand] = []  ## Script al ser derrotado (entrenadores)
@export var custom_scripts: Dictionary = {}  ## Scripts personalizados con nombre

## Añade un comando al script de interacción
func add_interact_command(command: ScriptCommand) -> void:
	on_interact.append(command)
	emit_changed()

## Añade un comando al script personalizado
func add_custom_command(script_name: String, command: ScriptCommand) -> void:
	if not custom_scripts.has(script_name):
		custom_scripts[script_name] = []
	custom_scripts[script_name].append(command)
	emit_changed()

## Obtiene un script por nombre
func get_script_by_name(name: String) -> Array[ScriptCommand]:
	if name == "interact":
		return on_interact
	elif name == "approach":
		return on_approach
	elif name == "sight":
		return on_sight
	elif name == "defeat":
		return on_defeat
	elif custom_scripts.has(name):
		return custom_scripts[name]
	return []
