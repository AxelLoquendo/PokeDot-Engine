@tool
extends EditorPlugin

class_name SpeciesEditorPlugin

var species_dock: SpeciesDock

func _enter_tree() -> void:
	species_dock = SpeciesDock.new()
	# Godot 4.7: DOCK_SLOT_BOTTOM_BR no existe, usamos add_control_to_bottom_panel
	add_control_to_bottom_panel(species_dock, "🔬 Species Editor")
	print("✓ Species Editor Plugin loaded")

func _exit_tree() -> void:
	if species_dock:
		remove_control_from_bottom_panel(species_dock)
		species_dock.queue_free()
	print("✓ Species Editor Plugin unloaded")
