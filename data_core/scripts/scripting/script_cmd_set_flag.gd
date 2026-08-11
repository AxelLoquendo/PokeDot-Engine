@tool
extends ScriptCommand
class_name ScriptCmdSetFlag

## Establece una bandera o variable global/local
## Las banderas se usan para trackear eventos completados

enum FlagType {
	GLOBAL,     ## Variable global persistente
	LOCAL,      ## Variable temporal del script
	MAP_FLAG,   ## Bandera específica del mapa
	NPC_FLAG    ## Bandera específica del NPC
}

@export var flag_type: FlagType = FlagType.GLOBAL
@export var flag_name: String = "evento_completado"
@export var value: Variant = true


func execute(context: ScriptExecutionContext) -> bool:
	match flag_type:
		FlagType.GLOBAL:
			# NO IMPLEMENTADO AUN - requiere SaveManager
			push_warning("ScriptCmdSetFlag: GLOBAL flags aun no implementadas")
					
		FlagType.LOCAL:
			context.set_variable(flag_name, value)
					
		FlagType.MAP_FLAG:
			# NO IMPLEMENTADO AUN
			push_warning("ScriptCmdSetFlag: MAP_FLAG aun no implementado")
					
		FlagType.NPC_FLAG:
			var npc_data: CharacterNpc = context.get_npc_data()
			if npc_data and npc_data.has_property("flags"):
				var flags: Dictionary = npc_data.flags as Dictionary
				flags[flag_name] = value
			else:
				push_warning("ScriptCmdSetFlag: NPC no tiene propiedad flags")
	
	return true


func get_display_text() -> String:
	var type_names: Array[String] = ["Global", "Local", "Mapa", "NPC"]
	return "🏳️ Bandera [%s]: %s = %s" % [type_names[flag_type], flag_name, str(value)]
