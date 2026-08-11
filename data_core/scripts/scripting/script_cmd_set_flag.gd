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
			# Usar tu sistema de guardado global
			if SaveManager.has_method("set_global_var"):
				SaveManager.set_global_var(flag_name, value)
			else:
				# Fallback a Autoload global
				if Engine.has_singleton("SaveManager"):
					Engine.get_singleton("SaveManager").set_global_var(flag_name, value)
					
		FlagType.LOCAL:
			context.set_variable(flag_name, value)
			
		FlagType.MAP_FLAG:
			if context.map and context.map.has_method("set_flag"):
				context.map.set_flag(flag_name, value)
				
		FlagType.NPC_FLAG:
			var npc_data = context.get_npc_data()
			if npc_data and npc_data.has_property("flags"):
				npc_data.flags[flag_name] = value
	
	return true

func get_display_text() -> String:
	var type_names = ["Global", "Local", "Mapa", "NPC"]
	return "🏳️ Bandera [%s]: %s = %s" % [type_names[flag_type], flag_name, str(value)]
