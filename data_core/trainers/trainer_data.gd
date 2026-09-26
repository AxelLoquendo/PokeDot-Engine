extends Resource
class_name TrainerData

## Entrenador de res://game/trainers/ (formato en docs/TRAINER.md).

## ID para trainerbattle. Al ganarle se activa una flag con este nombre.
@export var trainer_id: String = ""
@export var trainer_name: String = ""
@export var trainer_class: String = ""
## Todavía no se muestra en combate.
@export var pic: String = ""
## Dinero al ganar.
@export var money: int = 0
@export var double_battle: bool = false
## BattleSession.BattleType (música).
@export var battle_type: int = 2
@export var party: Array[TrainerPokemon] = []

## Para los mensajes de error.
var source_path: String = ""
var source_line: int = 0


## Clase + nombre.
func get_display_name() -> String:
	return ("%s %s" % [trainer_class, trainer_name]).strip_edges()


func build_party() -> Array[PokemonInstance]:
	var result: Array[PokemonInstance] = []
	for entry: TrainerPokemon in party:
		if entry != null:
			result.append(entry.create_instance())
	return result
