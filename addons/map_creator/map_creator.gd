@tool
extends EditorPlugin

const RUTA_PLANTILLA: String = "res://data_core/map/map_base/map_base.tscn"
const RUTA_POR_DEFECTO: String = "res://data_core/map/"
const ID_OPCION: int = 1001

func _enter_tree():
	add_tool_menu_item("🗺️ Crear nuevo mapa", _abrir_dialogo)


func _exit_tree():
	remove_tool_menu_item("🗺️ Crear nuevo mapa")


func _abrir_dialogo():
	var editor: EditorInterface = get_editor_interface()
	var dialogo: FileDialog = FileDialog.new()
	dialogo.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialogo.title = "Crear nuevo mapa"
	dialogo.access = FileDialog.ACCESS_FILESYSTEM
	dialogo.add_filter("*.tscn", "Escena de mapa")
	dialogo.current_dir = RUTA_POR_DEFECTO
	dialogo.current_file = "nuevo_mapa.tscn"
	
	editor.get_base_control().add_child(dialogo)
	dialogo.popup_centered()
	
	await dialogo.file_selected
	var ruta_guardado: String = dialogo.current_path
	dialogo.queue_free()
	
	var plantilla: PackedScene = load(RUTA_PLANTILLA)
	if not plantilla:
		editor.show_error_dialog("No se encontró la plantilla en:\n" + RUTA_PLANTILLA)
		return
	
	var resultado: Error = ResourceSaver.save(plantilla, ruta_guardado)
	if resultado == OK:
		print("Mapa creado en: ", ruta_guardado)
		EditorInterface.open_scene_from_path(ruta_guardado)
	else:
		editor.show_error_dialog("Error al guardar:\n" + str(resultado))
