@tool
extends EditorPlugin

class_name SpeciesEditorPlugin

const DOCK_SCRIPT := preload("res://addons/species_editor/species_dock.gd")

var species_dock: Control

func _enter_tree() -> void:
	species_dock = DOCK_SCRIPT.new()
	species_dock.name = "Species Editor"
	add_control_to_bottom_panel(species_dock, "🔬 Species Editor")
	print("Species Editor: plugin cargado")

func _exit_tree() -> void:
	if is_instance_valid(species_dock):
		remove_control_from_bottom_panel(species_dock)
		species_dock.queue_free()
	print("Species Editor: plugin descargado")
