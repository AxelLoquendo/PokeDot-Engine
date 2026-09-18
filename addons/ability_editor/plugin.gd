@tool
extends EditorPlugin

## Compatibility shim. The Ability editor is hosted by the unified workspace.
## It intentionally registers no bottom panel.
class_name AbilityEditorPlugin

func _enter_tree() -> void:
	# Keep this plugin loadable for existing projects without adding a dock.
	pass

func _exit_tree() -> void:
	# No control is registered here; the unified workspace owns the editor.
	pass
