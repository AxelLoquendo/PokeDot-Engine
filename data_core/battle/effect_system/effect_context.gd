## Contexto que se pasa a cada comando de efecto.
## Contiene todo lo que un efecto puede necesitar sin acoplarse al BattleManager.
class_name EffectContext
extends RefCounted

## Quién posee la habilidad / usa el movimiento / lleva el ítem
var user: BattleBattler = null

## Objetivo principal del evento (puede ser el mismo user)
var target: BattleBattler = null

## En contacto: el que golpeó (para on_hit_by)
var attacker: BattleBattler = null

## Movimiento involucrado (si aplica)
var move: MoveData = null

## Daño recién calculado / aplicado (0 si no hubo)
var damage: int = 0

## ¿El movimiento fue de contacto?
var is_contact: bool = false

## Referencia al combate (solo lectura de estado)
var battle: BattleManager = null

## Fuente del efecto (para mensajes y debugging)
var source_name: String = ""

## Tipo de fuente
enum SourceType { ABILITY, MOVE, ITEM, OTHER }
var source_type: SourceType = SourceType.OTHER

## Resultados / flags que los comandos pueden escribir
var blocked: bool = false
var modified_damage: int = -1
var messages: Array[String] = []

## Consultas (inmunidad / multiplicadores / flags)
var multiplier: float = 1.0
var immunity_reaction: String = ""
var query_bool: bool = false
var query_int: int = 0
var query_status: int = -1
var effectiveness: float = 1.0
var was_critical: bool = false
var vars: Dictionary = {}
var weather: int = -1
var terrain: int = -1
var move_category: int = -1

## Flags de consulta ampliados (tipados)
var acted_after_target: bool = false
var target_just_switched: bool = false
var stage_delta: int = 0
var redirect_target: BattleBattler = null


func _init(
	p_user: BattleBattler = null,
	p_target: BattleBattler = null,
	p_move: MoveData = null,
	p_battle: BattleManager = null
) -> void:
	user = p_user
	target = p_target
	move = p_move
	battle = p_battle
	if move != null:
		is_contact = move.makes_contact


func add_message(text: String) -> void:
	if not text.is_empty():
		messages.append(text)


func user_hp_percent() -> float:
	if user == null or user.pokemon == null or user.pokemon.max_hp <= 0:
		return 0.0
	return float(user.pokemon.current_hp) / float(user.pokemon.max_hp)


func target_hp_percent() -> float:
	if target == null or target.pokemon == null or target.pokemon.max_hp <= 0:
		return 0.0
	return float(target.pokemon.current_hp) / float(target.pokemon.max_hp)
