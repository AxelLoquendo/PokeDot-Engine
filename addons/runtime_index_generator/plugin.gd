@tool
extends EditorPlugin

const GENERATOR_SCRIPT := preload("res://data_core/generated/runtime_index_generator.gd")
const MENU_NAME: String = "Generar índices de datos runtime"

func _enter_tree() -> void:
	add_tool_menu_item(MENU_NAME, Callable(self, "_generate_indexes"))

func _exit_tree() -> void:
	remove_tool_menu_item(MENU_NAME)

func _generate_indexes() -> void:
	var generator := GENERATOR_SCRIPT.new() as RuntimeIndexGenerator
	var result: Error = generator.generate()
	if result != OK:
		push_error("RuntimeIndex: no se pudo escribir el índice: %s" % error_string(result))
		return
	EditorInterface.get_resource_filesystem().scan()
	print("RuntimeIndex: proceso terminado.")
