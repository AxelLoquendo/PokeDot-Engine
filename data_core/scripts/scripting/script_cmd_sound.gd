@tool
extends ScriptCommand
class_name ScriptCmdSound

## Reproduce efectos de sonido o música

enum SoundType {
	SFX,        ## Efecto de sonido
	MUSIC,      ## Música de fondo
	VOICE       ## Voz/narración
}

@export var sound_type: SoundType = SoundType.SFX
@export var sound_path: String = ""  ## Ruta al archivo de audio
@export var volume_db: float = 0.0
@export var loop: bool = false
@export var wait_until_finish: bool = false


func execute(context: ScriptExecutionContext) -> bool:
	if sound_path == "":
		return true
	
	var stream: AudioStream = load(sound_path) as AudioStream
	
	if not stream:
		push_error("ScriptCmdSound: No se pudo cargar el audio en %s" % sound_path)
		return true
	
	var audio_player: AudioStreamPlayer
	
	match sound_type:
		SoundType.SFX:
			audio_player = AudioStreamPlayer.new()
			audio_player.stream = stream
			audio_player.volume_db = volume_db
			if context.npc:
				context.npc.add_child(audio_player)
				audio_player.play()
				
				if wait_until_finish:
					audio_player.finished.connect(_on_sound_finished.bind(context))
					context.is_waiting = true
					return false
				else:
					audio_player.queue_free()
					return true
				
		SoundType.MUSIC:
			# NO IMPLEMENTADO AUN - requiere AudioManager
			push_warning("ScriptCmdSound: MUSIC aun no implementado")
			return true
				
		SoundType.VOICE:
			# Similar a SFX pero con bus diferente (si existe)
			audio_player = AudioStreamPlayer.new()
			audio_player.stream = stream
			audio_player.volume_db = volume_db
			# Intentar usar bus Voice si existe
			if AudioServer.get_bus_index("Voice") != -1:
				audio_player.bus = "Voice"
			if context.npc:
				context.npc.add_child(audio_player)
				audio_player.play()
				
				if wait_until_finish:
					audio_player.finished.connect(_on_sound_finished.bind(context))
					context.is_waiting = true
					return false
				else:
					audio_player.queue_free()
					return true
	
	return true


func _on_sound_finished(context: ScriptExecutionContext) -> void:
	context.is_waiting = false
	if context.npc and context.npc.has_node("ScriptRunner"):
		var runner: Node = context.npc.get_node("ScriptRunner")
		if runner.has_method("on_async_complete"):
			runner.call("on_async_complete")


func get_display_text() -> String:
	var type_names: Array[String] = ["SFX", "Música", "Voz"]
	return "🔊 %s: %s" % [type_names[sound_type], sound_path.get_file()]
