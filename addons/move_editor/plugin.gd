@tool
extends EditorPlugin

class_name MoveEditorPlugin

const DOCK_SCRIPT := preload("res://addons/move_editor/move_dock.gd")

var move_dock: Control

func _enter_tree() -> void:
	move_dock = DOCK_SCRIPT.new()
	move_dock.name = "Move Editor"
	add_control_to_bottom_panel(move_dock, "⚔ Move Editor")
	print("Move Editor: plugin cargado")

func _exit_tree() -> void:
	if is_instance_valid(move_dock):
		remove_control_from_bottom_panel(move_dock)
		move_dock.queue_free()
	print("Move Editor: plugin descargado")
