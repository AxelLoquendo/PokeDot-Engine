@tool
extends ScriptCommand
class_name ScriptCmdIf

## Ejecuta comandos hijos solo si se cumple una condición
## Los comandos hijos deben estar en un array separado

enum ConditionType {
	FLAG_IS_TRUE,
	FLAG_IS_FALSE,
	VARIABLE_EQUALS,
	HAS_ITEM,
	NPC_FACING_PLAYER,
	CUSTOM
}

@export var condition_type: ConditionType = ConditionType.FLAG_IS_TRUE
@export var flag_name: String = ""
@export var variable_name: String = ""
@export var compare_value: Variant = true
@export var custom_expression: String = ""  ## Para condiciones personalizadas

## Comandos que se ejecutan si la condición es verdadera
@export var then_commands: Array[ScriptCommand] = []
## Comandos que se ejecutan si la condición es falsa (opcional)
@export var else_commands: Array[ScriptCommand] = []

func execute(context: ScriptExecutionContext) -> bool:
	var condition_met: bool = _evaluate_condition(context)
	
	var commands_to_run = then_commands if condition_met else else_commands
	
	if commands_to_run.is_empty():
		return true
	
	# Ejecutar comandos hijos secuencialmente
	for command in commands_to_run:
		if not command or not command.enabled:
			continue
		
		var completed = command.execute(context)
		if not completed:
			# Comando asíncrono detectado, esperar
			context.is_waiting = true
			return false
	
	return true

func _evaluate_condition(context: ScriptExecutionContext) -> bool:
	match condition_type:
		ConditionType.FLAG_IS_TRUE:
			var flag_value = _get_flag_value(context, flag_name)
			return flag_value == true
			
		ConditionType.FLAG_IS_FALSE:
			var flag_value = _get_flag_value(context, flag_name)
			return flag_value == false
			
		ConditionType.VARIABLE_EQUALS:
			var var_value = context.get_variable(variable_name)
			return var_value == compare_value
			
		ConditionType.HAS_ITEM:
			if SaveManager.has_method("has_item"):
				return SaveManager.has_item(flag_name)  ## flag_name contiene el ID del item
			return false
			
		ConditionType.NPC_FACING_PLAYER:
			return context.is_player_facing_npc()
			
		ConditionType.CUSTOM:
			# Evaluar expresión personalizada (requiere precaución)
			return _evaluate_custom_expression(context, custom_expression)
	
	return false

func _get_flag_value(context: ScriptExecutionContext, name: String) -> Variant:
	#if SaveManager.has_method("get_global_var"):
	#	return SaveManager.get_global_var(name)
	return null

func _evaluate_custom_expression(context: ScriptExecutionContext, expression: String) -> bool:
	# Implementación básica - en producción usar un parser más seguro
	return true  ## Placeholder

func get_display_text() -> String:
	return "❓ SI: %s" % condition_type
