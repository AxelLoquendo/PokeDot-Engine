@tool
extends EditorPlugin
class_name AbilityEditorPlugin

const DOCK_SCRIPT := preload("res://addons/ability_editor/ability_dock.gd")

var ability_dock: Control

func _enter_tree() -> void:
	ability_dock = DOCK_SCRIPT.new()
	ability_dock.name = "Ability Editor"
	add_control_to_bottom_panel(ability_dock, "⚙ Ability Editor")

func _exit_tree() -> void:
	if is_instance_valid(ability_dock):
		remove_control_from_bottom_panel(ability_dock)
		ability_dock.queue_free()
		ability_dock = null
