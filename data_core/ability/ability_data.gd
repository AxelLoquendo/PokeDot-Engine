extends Resource
class_name AbilityData

## ─── Identificación ─────────────────────────────────────

@export var id: AbilityId.Id = AbilityId.Id.NONE
@export var name_key: String = ""
@export var description_key: String = ""

## ─── Clasificación ─────────────────────────────────────

@export var generation: int = 1
@export var is_hidden_ability: bool = false

@export_group("AI")
@export_range(-100, 100)
var ai_rating: int = 0

## ─── Activación ─────────────────────────────────────────

@export_group("Activation")

@export var triggers_on_enter: bool = false
@export var triggers_on_switch_in: bool = false
@export var triggers_on_hit: bool = false
@export var triggers_on_hit_by: bool = false
@export var triggers_on_faint: bool = false
@export var triggers_on_stat_change: bool = false
@export var triggers_on_status: bool = false
@export var triggers_on_weather: bool = false
@export var triggers_on_terrain: bool = false


## ─── Datos de gameplay ─────────────────────────────────

@export_group("Gameplay")

@export var weather_override: WeatherEffect.WeatherID = \
	WeatherEffect.WeatherID.WEATHER_NONE

@export var terrain_override: String = ""

@export var stat_modifiers: Dictionary = {}

@export var priority_modifier: int = 0


## ─── Comportamiento ────────────────────────────────────

@export_group("Behavior")

@export var behavior: AbilityEffect = null


## ─── Validación ─────────────────────────────────────────

func _validate() -> Array[String]:
	var errors: Array[String] = []

	if id == AbilityId.Id.COUNT:
		errors.append("El ID no puede ser COUNT")

	if name_key.is_empty():
		errors.append("name_key está vacío")

	if generation < 1:
		errors.append("generation debe ser mayor o igual a 1")

	# if _has_any_trigger() and behavior == null:
#     errors.append("Tiene triggers activados pero 'behavior' es null")

	return errors


func is_valid() -> bool:
	return _validate().is_empty()


func _has_any_trigger() -> bool:
	return (
		triggers_on_enter
		or triggers_on_switch_in
		or triggers_on_hit
		or triggers_on_hit_by
		or triggers_on_faint
		or triggers_on_stat_change
		or triggers_on_status
		or triggers_on_weather
		or triggers_on_terrain
	)
