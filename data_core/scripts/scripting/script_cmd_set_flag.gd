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
			context.set_global_flag(flag_name, value)
					
		FlagType.LOCAL:
			context.set_variable(flag_name, value)
					
		FlagType.MAP_FLAG:
			context.set_variable("map_" + flag_name, value)
					
		FlagType.NPC_FLAG:
			var npc_data: CharacterNpc = context.get_npc_data()
			if npc_data:
				push_warning("ScriptCmdSetFlag: NPC_FLAG aun no implementado")
			else:
				push_warning("ScriptCmdSetFlag: no se encontro el recurso del NPC")
	
	return true


func get_display_text() -> String:
	var type_names: Array[String] = ["Global", "Local", "Mapa", "NPC"]
	return "🏳️ Bandera [%s]: %s = %s" % [type_names[flag_type], flag_name, str(value)]
