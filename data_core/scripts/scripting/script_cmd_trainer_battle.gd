@tool
extends ScriptCommand
class_name ScriptCmdTrainerBattle

## trainerbattle TRAINER_ID
## Combate contra un entrenador de res://game/trainers/ y espera a que acabe.
## Si gana el jugador, activa la flag TRAINER_ID y deja last_result = true.
## Si ya estaba derrotado, no hay combate y last_result = true.
@export var trainer_id: String = ""


func execute(context: ScriptExecutionContext) -> bool:
	context.set_variable("last_result", false)
	var trainer: TrainerData = TrainerDatabase.get_trainer(trainer_id)
	if trainer == null:
		push_error("trainerbattle: no existe el entrenador '%s' en %s" % [trainer_id, TrainerDatabase.TRAINERS_DIR])
		return true
	if bool(context.get_global_flag(trainer.trainer_id, false)):
		context.set_variable("last_result", true)
		return true

	var player: CharacterController = context.player as CharacterController
	if player == null:
		push_error("trainerbattle: el script no tiene jugador")
		return true
	if BattleSession.is_active:
		push_error("trainerbattle: ya hay un combate en curso")
		return true
	if not BattleSession.preparar_desde_entrenador(player, trainer):
		return true

	# BattleSession libera al jugador al terminar; se respeta el lock del script.
	var was_locked: bool = player.ejecutando_evento
	context.is_waiting = true
	BattleSession.battle_finished.connect(func(result: int) -> void:
		var won: bool = result == BattleSession.BattleResult.WIN
		if won:
			context.set_global_flag(trainer.trainer_id, true)
		context.set_variable("last_result", won)
		if is_instance_valid(player):
			player.ejecutando_evento = was_locked
		context.complete_async()
	, CONNECT_ONE_SHOT)
	_start_battle(player)
	return false


## Misma entrada que un encuentro salvaje: música, transición y overlay.
func _start_battle(player: CharacterController) -> void:
	player.ejecutando_evento = true
	MusicManager.reproducir_batalla(BattleSession.battle_music)
	await TransicionManager.transicion_encuentro_salvaje()
	var parent: Node = player.get_tree().current_scene
	if parent == null:
		parent = player.get_tree().root
	BattleSession.iniciar_como_overlay(parent)
	await TransicionManager.fade_in(0.25)


func get_display_text() -> String:
	return "Combate contra %s" % trainer_id
