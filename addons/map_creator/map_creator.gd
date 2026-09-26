@tool
extends EditorPlugin

const RUTA_PLANTILLA: String = "res://data_core/map/map_base/map_base.tscn"
const RUTA_POR_DEFECTO: String = "res://game/"
const NODO_RAIZ_PLANTILLA: String = "MapData"
const MENU_CREAR: String = "🗺️ Crear nuevo mapa"
const MENU_REGISTRO: String = "🗺️ Actualizar registro de mapas"


func _enter_tree() -> void:
	add_tool_menu_item(MENU_CREAR, _abrir_dialogo)
	add_tool_menu_item(MENU_REGISTRO, actualizar_registro.bind(true))
	scene_saved.connect(_on_scene_saved)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_CREAR)
	remove_tool_menu_item(MENU_REGISTRO)
	if scene_saved.is_connected(_on_scene_saved):
		scene_saved.disconnect(_on_scene_saved)


# Regenera el registro al guardar un mapa.
func _on_scene_saved(ruta: String) -> void:
	if MapRegistryGenerator.read_map_root(ruta).is_empty() and not _esta_registrada(ruta):
		return
	actualizar_registro(false)


func actualizar_registro(mostrar_resumen: bool) -> void:
	var generador: MapRegistryGenerator = MapRegistryGenerator.new()
	var error: Error = generador.generate()
	if error != OK:
		push_error("MapRegistry: no se pudo escribir el registro: %s" % error_string(error))
		return
	_recargar_script(MapRegistryGenerator.OUTPUT_PATH)
	EditorInterface.get_resource_filesystem().update_file(MapRegistryGenerator.OUTPUT_PATH)
	if mostrar_resumen:
		var texto: String = "Mapas registrados: %d" % MapRegistry.MAPS.size()
		if not generador.warnings.is_empty():
			texto += "\n\nAvisos:\n- " + "\n- ".join(generador.warnings)
		_mostrar_mensaje("Registro de mapas", texto)


func _abrir_dialogo() -> void:
	var dialogo: EditorFileDialog = EditorFileDialog.new()
	dialogo.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	dialogo.access = EditorFileDialog.ACCESS_RESOURCES
	dialogo.title = "Crear nuevo mapa"
	dialogo.add_filter("*.tscn", "Escena de mapa")
	dialogo.current_dir = RUTA_POR_DEFECTO
	dialogo.current_file = "nuevo_mapa.tscn"
	dialogo.file_selected.connect(func(ruta: String) -> void:
		dialogo.queue_free()
		_crear_mapa(ruta)
	)
	dialogo.canceled.connect(dialogo.queue_free)
	EditorInterface.get_base_control().add_child(dialogo)
	dialogo.popup_file_dialog()


# ruta_1.tscn -> MAPSEC_RUTA_1
func _crear_mapa(ruta: String) -> void:
	if load(RUTA_PLANTILLA) == null:
		EditorInterface.get_editor_toaster().push_toast("No se encontró la plantilla " + RUTA_PLANTILLA, EditorToaster.SEVERITY_ERROR)
		return

	var nombre_mapa: String = ruta.get_file().get_basename().capitalize()
	var clave: String = MapRegistryGenerator.make_section_key(nombre_mapa)
	if clave.is_empty():
		_mostrar_mensaje("Crear nuevo mapa", "El nombre del archivo debe tener letras o números.")
		return
	var existentes: Dictionary = MapRegistryGenerator.read_section_enum()
	if existentes.has(clave) and MapSection.is_registered(int(existentes[clave])):
		_mostrar_mensaje("Crear nuevo mapa", "%s ya pertenece a %s.\nElige otro nombre de archivo." % [
			clave, MapSection.get_scene_path(int(existentes[clave]))
		])
		return

	var id_seccion: int = MapRegistryGenerator.add_section(clave)
	if id_seccion < 0:
		_mostrar_mensaje("Crear nuevo mapa", "No se pudo escribir %s." % MapRegistryGenerator.SECTION_SCRIPT_PATH)
		return
	_recargar_script(MapRegistryGenerator.SECTION_SCRIPT_PATH)

	var contenido_tscn: String = ""
	contenido_tscn += "[gd_scene load_steps=2 format=3]\n\n"
	contenido_tscn += "[ext_resource type=\"PackedScene\" path=\"" + RUTA_PLANTILLA + "\" id=\"1_base\"]\n\n"
	contenido_tscn += "[node name=\"" + NODO_RAIZ_PLANTILLA + "\" instance=ExtResource(\"1_base\")]\n"
	contenido_tscn += "map_name = %s\n" % var_to_str(nombre_mapa)
	contenido_tscn += "map_id_section = %d\n" % id_seccion

	var archivo: FileAccess = FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		_mostrar_mensaje("Crear nuevo mapa", "Error al guardar:\n" + error_string(FileAccess.get_open_error()))
		return
	archivo.store_string(contenido_tscn)
	archivo.close()

	actualizar_registro(false)
	EditorInterface.get_resource_filesystem().scan()
	print("✅ Mapa creado en %s como %s (%d)." % [ruta, clave, id_seccion])
	EditorInterface.open_scene_from_path(ruta)


func _esta_registrada(ruta: String) -> bool:
	for entrada: Dictionary in MapRegistry.MAPS.values():
		if str(entrada.get("path", "")) == ruta:
			return true
	return false


# El editor no recarga solo un script editado desde aquí.
func _recargar_script(ruta: String) -> void:
	var script: GDScript = load(ruta) as GDScript
	if script == null:
		return
	script.source_code = FileAccess.get_file_as_string(ruta)
	script.reload(true)


func _mostrar_mensaje(titulo: String, texto: String) -> void:
	var dialogo: AcceptDialog = AcceptDialog.new()
	dialogo.title = titulo
	dialogo.dialog_text = texto
	dialogo.confirmed.connect(dialogo.queue_free)
	dialogo.canceled.connect(dialogo.queue_free)
	EditorInterface.get_base_control().add_child(dialogo)
	dialogo.popup_centered()
