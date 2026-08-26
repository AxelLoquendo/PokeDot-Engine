@tool
extends EditorPlugin

class_name SpeciesEditorPlugin

const DOCK_SCRIPT := preload("res://addons/species_editor/species_dock.gd")

var species_dock: Control

func _enter_tree() -> void:
	set_process_input(true)
	species_dock = DOCK_SCRIPT.new()
	species_dock.name = "Species Editor"
	add_control_to_bottom_panel(species_dock, "🔬 Species Editor")
	print("Species Editor: plugin cargado")

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_S and (key_event.ctrl_pressed or key_event.meta_pressed):
			if is_instance_valid(species_dock) and species_dock.has_method("save_all_from_shortcut"):
				species_dock.call_deferred("save_all_from_shortcut")
			# Do not consume the event: Godot must still save the scene/script.

func _exit_tree() -> void:
	if is_instance_valid(species_dock):
		remove_control_from_bottom_panel(species_dock)
		species_dock.queue_free()
	print("Species Editor: plugin descargado")
