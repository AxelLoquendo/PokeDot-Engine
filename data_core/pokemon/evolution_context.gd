extends RefCounted

class_name EvolutionContext

## Contexto explícito de una comprobación. El sistema no depende de escenas.
var pokemon: PokemonInstance
var mode: PokemonData.EvolutionMode = PokemonData.EvolutionMode.EVO_MODE_NORMAL

## Datos aportados por el sistema que inició la comprobación.
var used_item_id: int = 0
var trade_partner_species_id: int = 0
var current_map_id: int = 0
var current_region_id: int = 0
var current_weather_id: int = 0
var is_day: bool = true
var party: Array[PokemonInstance] = []
var event_flags: Dictionary = {}

func _init(value: PokemonInstance = null) -> void:
	pokemon = value

func has_event_flag(flag: StringName) -> bool:
	return bool(event_flags.get(flag, false))
