@tool
extends EditorPlugin

class_name SpeciesEditorPlugin

var species_dock: SpeciesDock
var undo_redo: EditorUndoRedo

func _enter_tree() -> void:
	undo_redo = get_undo_redo()
	species_dock = SpeciesDock.new()
	# Posicionar en el panel inferior (como Output, Debugger, etc)
	add_control_to_dock(DOCK_SLOT_BOTTOM_BR, species_dock)
	print("✓ Species Editor Plugin loaded")

func _exit_tree() -> void:
	if species_dock:
		remove_control_from_docks(species_dock)
		species_dock.queue_free()
	print("✓ Species Editor Plugin unloaded")
