extends Node
## Autoload: MusicManager
## Reproduce BGM. Las rutas salen de SFXGame (catálogo).

var _reproductor: AudioStreamPlayer
var _ruta_actual: String = ""
var _duracion_total: float = 0.0
var _silencio_a_cortar: float = 0.0


func _ready() -> void:
	_reproductor = AudioStreamPlayer.new()
	_reproductor.name = "BGM_Player"
	_reproductor.bus = "Music"
	add_child(_reproductor)


func _process(_delta: float) -> void:
	if _reproductor.stream == null or _ruta_actual.is_empty():
		return
	if _silencio_a_cortar <= 0.0:
		return
	var posicion: float = _reproductor.get_playback_position()
	if posicion >= _duracion_total - _silencio_a_cortar - 0.02:
		_reproductor.seek(0.0)


## API baja (debug / casos raros)
func reproducir(ruta: String, cortar_silencio: float = 0.0) -> void:
	if ruta == _ruta_actual:
		_silencio_a_cortar = maxf(cortar_silencio, 0.0)
		return

	if ruta.is_empty():
		_reproductor.volume_db = -80.0
		_reproductor.stop()
		_ruta_actual = ""
		_silencio_a_cortar = 0.0
		return

	if not ResourceLoader.exists(ruta):
		push_warning("MusicManager: no existe %s" % ruta)
		return

	var nueva: AudioStream = load(ruta) as AudioStream
	if nueva == null:
		push_warning("MusicManager: no se pudo cargar %s" % ruta)
		return

	_ruta_actual = ruta
	_duracion_total = nueva.get_length()
	_silencio_a_cortar = maxf(cortar_silencio, 0.0)
	_reproductor.stream = nueva
	_reproductor.volume_db = 0.0
	_reproductor.play()


## API alta — catálogo SFXGame
func reproducir_mapa(id: SFXGame.MapMusicID) -> void:
	if id == SFXGame.MapMusicID.BGM_NONE:
		detener()
		return
	reproducir(SFXGame.map_music_path(id), SFXGame.DEFAULT_TRIM_END)


func reproducir_batalla(id: SFXGame.BattleMusicID) -> void:
	reproducir(SFXGame.battle_music_path(id), SFXGame.DEFAULT_TRIM_END)


func reproducir_efecto_musical(id: SFXGame.MusicEffectID) -> void:
	## Jingle: suele ir en otro player; si quieres reutilizar BGM:
	reproducir(SFXGame.music_effect_path(id), 0.0)


func detener() -> void:
	_reproductor.stop()
	_ruta_actual = ""
	_silencio_a_cortar = 0.0
	_reproductor.volume_db = 0.0


func esta_sonando() -> bool:
	return _reproductor.playing


func ruta_actual() -> String:
	return _ruta_actual
