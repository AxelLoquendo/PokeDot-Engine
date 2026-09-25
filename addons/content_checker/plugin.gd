@tool
extends EditorPlugin

const MENU_NAME: String = "🔎 Revisar contenido"


func _enter_tree() -> void:
	add_tool_menu_item(MENU_NAME, _run_checks)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_NAME)


func _run_checks() -> void:
	var checker: ContentChecker = ContentChecker.new()
	checker.run()
	var summary: String = "Errores: %d\nAvisos: %d" % [checker.errors.size(), checker.warnings.size()]
	if checker.errors.is_empty() and checker.warnings.is_empty():
		summary = "Todo en orden: no se encontraron problemas."
	else:
		print("\n=== Revisar contenido ===\n%s\n" % checker.get_report())
		summary += "\n\nLa lista completa está en la pestaña Salida."

	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Revisar contenido"
	dialog.dialog_text = summary
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()
