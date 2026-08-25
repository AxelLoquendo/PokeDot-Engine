@tool
extends RefCounted

class_name EvolutionTrigger

enum Trigger {
	LEVEL_UP,
	LEVEL_UP_BATTLE_ONLY,
	ITEM_USED,
	TRADE,
	BATTLE_END,
	OVERWORLD_EVENT,
	SCRIPT_EVENT,
}

static func display_name(trigger: Trigger) -> String:
	match trigger:
		Trigger.LEVEL_UP:
			return "Subir de nivel"
		Trigger.LEVEL_UP_BATTLE_ONLY:
			return "Subir de nivel (batalla)"
		Trigger.ITEM_USED:
			return "Usar objeto"
		Trigger.TRADE:
			return "Intercambio"
		Trigger.BATTLE_END:
			return "Final de batalla"
		Trigger.OVERWORLD_EVENT:
			return "Evento de mundo"
		Trigger.SCRIPT_EVENT:
			return "Evento de script"
	return "Desconocido"
