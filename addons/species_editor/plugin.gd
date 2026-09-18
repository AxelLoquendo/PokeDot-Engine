@tool
extends EditorPlugin

## Registers the single unified workspace. Individual editor plugins are not
## enabled here because their docks are instantiated lazily by the workspace.
class_name PokeDotEnginePlugin

const WORKSPACE_SCRIPT: Script = preload("res://addons/species_editor/species_editor_window.gd")
var workspace: Window

func _enter_tree() -> void:
	add_tool_menu_item("PokeDot Engine", _open_workspace)

func _exit_tree() -> void:
	remove_tool_menu_item("PokeDot Engine")
	if is_instance_valid(workspace):
		workspace.queue_free()
		workspace = null

func _open_workspace() -> void:
	if not is_instance_valid(workspace):
		workspace = WORKSPACE_SCRIPT.new()
		workspace.name = "PokeDotEngineWorkspace"
		get_editor_interface().get_base_control().add_child(workspace)
	if workspace.is_inside_tree():
		workspace.show()
		workspace.popup_centered()
