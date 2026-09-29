@tool
extends Resource
class_name AbilityData

## ─── Identificación ─────────────────────────────────────
@export var id: AbilityId.Id = AbilityId.Id.NONE
@export var name_key: String = ""
@export var description_key: String = ""

## ─── Clasificación ─────────────────────────────────────
@export var generation: int = 1
@export var is_hidden_ability: bool = false

## ─── AI (pokeemerald-expansion) ─────────────────────────
## Puntuación heurística para la IA de batalla (−100…100).
## Positivo = la IA valora más tener / sacar esta habilidad
## (Intimidate, Weather setters, etc.). Negativo = la evita
## (p.ej. Truant, Defeatist). Se usa al elegir movimientos
## y al priorizar reservas al cambiar.
@export_group("AI")
@export_range(-100, 100)
var ai_rating: int = 0

## ─── Activación (LEGACY / documentación) ────────────────
## Los scripts .txt definen cuándo actúa cada habilidad.
## Estos flags ya no gatean el runtime; se mantienen por
## compatibilidad con .tres existentes y herramientas.
@export_group("Activation (legacy — scripts .txt mandan)")
@export var triggers_on_enter: bool = false
@export var triggers_on_switch_in: bool = false
@export var triggers_on_hit: bool = false
@export var triggers_on_hit_by: bool = false
@export var triggers_on_faint: bool = false
@export var triggers_on_stat_change: bool = false
@export var triggers_on_status: bool = false
@export var triggers_on_weather: bool = false
@export var triggers_on_terrain: bool = false

## ─── Gameplay (LEGACY) ──────────────────────────────────
## Preferir comandos en scripts (set_weather, raise_stat…).
@export_group("Gameplay (legacy — preferir scripts)")
@export var weather_override: AbilityBattleEffect.weatherAbilityID = \
	AbilityBattleEffect.weatherAbilityID.WEATHER_NONE
@export var terrain_override: AbilityBattleEffect.terrainID = AbilityBattleEffect.terrainID.TERRAIN_NONE
@export var stat_modifiers: Dictionary = {}
@export var priority_modifier: int = 0

## ─── Behavior (OBSOLETO) ────────────────────────────────
## Sustituido por data_core/battle/effect_system/scripts/abilities/<id>.txt
@export_group("Behavior (obsoleto — usar scripts .txt)")
@export var behavior: AbilityEffect = null


func _validate() -> Array[String]:
	var errors: Array[String] = []
	if id == AbilityId.Id.COUNT:
		errors.append("El ID no puede ser COUNT")
	if name_key.is_empty():
		errors.append("name_key está vacío")
	if generation < 1:
		errors.append("generation debe ser mayor o igual a 1")
	return errors


func is_valid() -> bool:
	return _validate().is_empty()
