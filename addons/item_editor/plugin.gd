@tool
extends EditorPlugin

## Enable this plugin from Project > Project Settings > Plugins after copying
## this folder to res://addons/item_editor/.
class_name ItemEditorPlugin

const DOCK_SCRIPT := preload("res://addons/item_editor/item_dock.gd")
var item_dock: ItemEditorDock

func _enter_tree() -> void:
	item_dock = DOCK_SCRIPT.new()
	item_dock.name = "Item Editor"
	add_control_to_bottom_panel(item_dock, "🧰 Item Editor")

func _exit_tree() -> void:
	if is_instance_valid(item_dock):
		remove_control_from_bottom_panel(item_dock)
		item_dock.queue_free()
		item_dock = null
