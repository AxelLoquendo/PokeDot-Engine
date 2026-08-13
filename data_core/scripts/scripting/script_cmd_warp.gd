@tool
extends ScriptCommand
class_name ScriptCmdWarp

## Warp de campo: siempre afecta al jugador y usa una sección MAPSEC_*.
@export var target_map: String = ""
@export var target_tile: Vector2i = Vector2i.ZERO
@export_range(0.05, 5.0, 0.05) var fade_duration: float = 0.5


func execute(context: ScriptExecutionContext) -> bool:
	var player: CharacterController = context.player as CharacterController
	if player == null or player.map_manager == null:
		push_error("ScriptCmdWarp: no se encontró al jugador o su MapManager")
		return true
	var section_id: int = _section_from_text(target_map)
	if section_id < 0:
		push_error("ScriptCmdWarp: MAPSEC desconocido '%s'" % target_map)
		return true
	context.is_waiting = true
	var fade_out_finished: Signal = TransicionManager.fade_out(fade_duration)
	fade_out_finished.connect(func() -> void:
		player.map_manager.warp_player_to_section(section_id, target_tile)
		var fade_in_finished: Signal = TransicionManager.fade_in(fade_duration)
		fade_in_finished.connect(context.complete_async, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)
	return false


func _section_from_text(section_name: String) -> int:
	var normalized: String = section_name.to_upper()
	if MapSection.SectionId.has(normalized):
		return int(MapSection.SectionId[normalized])
	return -1


func get_display_text() -> String:
	return "Warp jugador a %s (%d, %d)" % [target_map, target_tile.x, target_tile.y]
