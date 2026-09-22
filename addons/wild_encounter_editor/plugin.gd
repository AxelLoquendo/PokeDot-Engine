@tool
extends EditorPlugin

## Compatibility shim. Wild Encounters is hosted by the unified workspace.
## It intentionally registers no bottom panel or standalone dock.
class_name WildEncounterEditorPlugin

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass
