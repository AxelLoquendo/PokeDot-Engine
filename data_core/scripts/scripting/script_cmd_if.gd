@tool
extends ScriptCommand
class_name ScriptCmdIf

## Ejecuta comandos hijos solo si se cumple una condición
## Los comandos hijos deben estar en un array separado

enum ConditionType {
	FLAG_IS_TRUE,
	FLAG_IS_FALSE,
	VARIABLE_EQUALS,
	HAS_ITEM,       ## NO IMPLEMENTADO AUN
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


func get_inline_commands(context: ScriptExecutionContext) -> Array[ScriptCommand]:
	var condition_met: bool = _evaluate_condition(context)
	return (then_commands if condition_met else else_commands).duplicate()


func execute(context: ScriptExecutionContext) -> bool:
	var condition_met: bool = _evaluate_condition(context)
	
	var commands_to_run: Array[ScriptCommand] = then_commands if condition_met else else_commands
	
	if commands_to_run.is_empty():
		return true
	
	# Ejecutar comandos hijos secuencialmente
	for command: ScriptCommand in commands_to_run:
		if not command or not command.enabled:
			continue
		
		var completed: bool = command.execute(context)
		if not completed:
			# Comando asíncrono detectado, esperar
			context.is_waiting = true
			return false
	
	return true


func _evaluate_condition(context: ScriptExecutionContext) -> bool:
	match condition_type:
		ConditionType.FLAG_IS_TRUE:
			var flag_value: Variant = _get_flag_value(context, flag_name)
			return flag_value == true
				
		ConditionType.FLAG_IS_FALSE:
			var flag_value: Variant = _get_flag_value(context, flag_name)
			return flag_value == false
				
		ConditionType.VARIABLE_EQUALS:
			var var_value: Variant = context.get_variable(variable_name)
			return var_value == compare_value
				
		ConditionType.HAS_ITEM:
			# NO IMPLEMENTADO AUN - requiere sistema de items
			push_warning("ScriptCmdIf: HAS_ITEM aun no implementado")
			return false
				
		ConditionType.NPC_FACING_PLAYER:
			return context.is_player_facing_npc()
				
		ConditionType.CUSTOM:
			# Evaluar expresión personalizada (requiere precaución)
			return _evaluate_custom_expression(context, custom_expression)
	
	return false


func _get_flag_value(_context: ScriptExecutionContext, _name: String) -> Variant:
	# NO IMPLEMENTADO AUN - requiere SaveManager
	return null


func _evaluate_custom_expression(_context: ScriptExecutionContext, _expression: String) -> bool:
	# Implementación básica - en producción usar un parser más seguro
	return true  ## Placeholder


func get_display_text() -> String:
	return "❓ SI: %s" % ConditionType.keys()[condition_type]
