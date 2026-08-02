@tool
extends EditorPlugin

var layer_actual: TileMapLayer = null
var mapa_actual: MapAttributes = null

var firma_anterior: int = 0


func _handles(object: Object) -> bool:
	return object is TileMapLayer


func _edit(object: Object) -> void:

	if object == null or !(object is TileMapLayer):
		layer_actual = null
		mapa_actual = null
		return

	layer_actual = object as TileMapLayer
	mapa_actual = obtener_mapa(layer_actual)

	if mapa_actual:
		print("Mapa:", mapa_actual.map_name)

	actualizar_firma()


func _process(_delta: float) -> void:

	if layer_actual == null:
		return

	if mapa_actual == null:
		return

	var firma := calcular_firma()

	if firma != firma_anterior:

		firma_anterior = firma

		limpiar_fuera_del_mapa()

func calcular_firma() -> int:

	var firma: int = 17

	for cell: Vector2i in layer_actual.get_used_cells():

		firma = firma * 31 + cell.x
		firma = firma * 31 + cell.y

	return firma

func actualizar_firma() -> void:
	firma_anterior = calcular_firma()

func limpiar_fuera_del_mapa() -> void:

	var cambiado := false

	var cells: Array[Vector2i] = layer_actual.get_used_cells()

	for cell: Vector2i in cells:

		if (
			cell.x < 0
			or cell.y < 0
			or cell.x >= mapa_actual.map_size.x
			or cell.y >= mapa_actual.map_size.y
		):

			layer_actual.erase_cell(cell)
			cambiado = true

	if cambiado:
		actualizar_firma()

func obtener_mapa(layer: TileMapLayer) -> MapAttributes:

	var nodo: Node = layer

	while nodo:

		if nodo is MapAttributes:
			return nodo as MapAttributes

		nodo = nodo.get_parent()

	return null
