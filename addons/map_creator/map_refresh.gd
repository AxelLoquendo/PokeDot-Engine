@tool
extends EditorScript

const RUTA_PLANTILLA: String = "res://data_core/map/map_base/map_base.tscn"
const RUTAS_RAIZ: Array[String] = [
	"res://data_core/map/",
	"res://game/data_core_eb/map_eb/"
]
const NODO_RAIZ: String = "MapData"
const EXCLUIR: Array[String] = ["gestor_position", "gestor_inicio"]

const PROPIAS_PROPIEDADES: Array[String] = [
	"map_name", "map_id_section", "map_region", "map_size",
	"color_borde", "tile_size", "mostrar_limite", "is_indoor",
	"allow_escape_rope", "allow_fly", "north_map", "east_map",
	"south_map", "west_map", "music_path", "silence_end"
]

# Capas que SÍ conservamos su contenido
const RUTAS_CAPAS_CONSERVAR: Array[String] = [
	"Tilesets/Tile0",
	"Tilesets/Tile1",
	"Tilesets/Tile2",
	"Tilesets/Tile3",
	"Behaviours/Borde"
]

# Capa que NO conservamos: heredará la colisión de map_base
const RUTA_CAPA_COLISION: String = "Behaviours/Collisions"


func _buscar(ruta: String) -> PackedStringArray:
	var resultados: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(ruta)
	if not dir:
		return resultados
	dir.list_dir_begin()
	var nombre: String = dir.get_next()
	while nombre != "":
		var ruta_completa: String = ruta.path_join(nombre)
		var saltar: bool = false
		for palabra in EXCLUIR:
			if ruta_completa.contains(palabra):
				saltar = true
				break
		if not saltar:
			if dir.current_is_dir():
				resultados.append_array(_buscar(ruta_completa))
			elif ruta_completa.ends_with(".tscn") and ruta_completa != RUTA_PLANTILLA:
				resultados.append(ruta_completa)
		nombre = dir.get_next()
	return resultados


func _existe_propiedad(nodo: Node, nombre_prop: String) -> bool:
	for prop in nodo.get_property_list():
		if prop.name == nombre_prop:
			return true
	return false


func _extraer_capas(raiz: Node) -> Dictionary:
	var capas: Dictionary = {}
	print("   🔍 Buscando capas a conservar...")
	
	for ruta_capa in RUTAS_CAPAS_CONSERVAR:
		var nodo = raiz.get_node_or_null(ruta_capa)
		if nodo and nodo is TileMapLayer:
			print("      ✔️ Conservando: ", ruta_capa)
			
			var tileset_original: TileSet = nodo.tile_set
			if tileset_original:
				print("         ✅ TileSet conservado")
			
			var casillas: Dictionary = {}
			for pos in nodo.get_used_cells():
				var fuente: int = nodo.get_cell_source_id(pos)
				var coords: Vector2i = nodo.get_cell_atlas_coords(pos)
				casillas[pos] = [fuente, coords]
			
			print("         ✅ Casillas leídas: ", casillas.size())
			
			capas[ruta_capa] = {
				"tileset": tileset_original,
				"casillas": casillas
			}
		else:
			print("      ⚠️ No encontrada: ", ruta_capa)
	
	# Confirmamos que la colisión se mantendrá de la plantilla
	print("      ℹ️ La capa Behaviours/Collisions usará la definición de map_base")
	
	return capas


func _run() -> void:
	print("\n🔍 Buscando mapas...")
	var todos_los_mapas: PackedStringArray = []
	for ruta in RUTAS_RAIZ:
		todos_los_mapas.append_array(_buscar(ruta))
	print("✅ Total mapas: ", todos_los_mapas.size(), "\n")

	for ruta in todos_los_mapas:
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("🔄 Procesando: ", ruta)
		
		var escena_original = load(ruta)
		if not escena_original:
			print("   ❌ No se pudo cargar")
			continue
		var raiz_original = escena_original.instantiate()
		if not raiz_original:
			print("   ❌ No se pudo instanciar")
			continue
		print("   ✅ Escena cargada")

		var capas_guardadas = _extraer_capas(raiz_original)
		print("   🛡️ Total capas conservadas: ", capas_guardadas.size())

		var datos_mapa: Dictionary = {}
		for prop in PROPIAS_PROPIEDADES:
			if _existe_propiedad(raiz_original, prop):
				datos_mapa[prop] = raiz_original.get(prop)

		var plantilla = load(RUTA_PLANTILLA)
		if not plantilla:
			print("   ❌ No se encontró plantilla")
			raiz_original.queue_free()
			continue
		var raiz_nueva = plantilla.instantiate()
		raiz_nueva.name = NODO_RAIZ

		for prop in datos_mapa:
			raiz_nueva.set(prop, datos_mapa[prop])

		# Restaurar solo las capas visuales y borde
		for ruta_capa in capas_guardadas:
			var datos = capas_guardadas[ruta_capa]
			var nodo_destino = raiz_nueva.get_node_or_null(ruta_capa)
			
			if not nodo_destino:
				print("   ⚠️ Sin destino para: ", ruta_capa)
				continue

			nodo_destino.tile_set = datos["tileset"]
			print("   ✅ TileSet asignado: ", ruta_capa)

			nodo_destino.clear()
			for pos in datos["casillas"]:
				var fuente: int = datos["casillas"][pos][0]
				var coords: Vector2i = datos["casillas"][pos][1]
				nodo_destino.set_cell(pos, fuente, coords)
			print("   ✅ Contenido restaurado: ", ruta_capa)

		# Aseguramos que la colisión quede LIMPIA para usar la de plantilla
		var capa_colision = raiz_nueva.get_node_or_null(RUTA_CAPA_COLISION)
		if capa_colision and capa_colision is TileMapLayer:
			capa_colision.clear()
			print("   ✅ Colisión limpia: se usa la definición de map_base")

		var escena_final = PackedScene.new()
		if escena_final.pack(raiz_nueva) == OK:
			if ResourceSaver.save(escena_final, ruta) == OK:
				print("✅ MAPA ACTUALIZADO CORRECTAMENTE\n")
			else:
				print("   ❌ Error al guardar el archivo\n")
		else:
			print("   ❌ Error al empaquetar la escena\n")

		raiz_original.queue_free()
		raiz_nueva.queue_free()

	print("\n🎉 TERMINADO: Todo listo con la colisión de la plantilla!")
