extends Node

var _reproductor: AudioStreamPlayer
var _ruta_actual: String = ""
var _duracion_total: float = 0.0
var _silencio_a_cortar: float = 0.0


func _ready() -> void:
	_reproductor = AudioStreamPlayer.new()
	_reproductor.name = "BGM_Player"
	_reproductor.bus = "Music"
	add_child(_reproductor)
	print("MusicManager listo")


func _process(_delta: float) -> void:
	if not _reproductor.stream or _ruta_actual.is_empty():
		return

	var posicion: float = _reproductor.get_playback_position()

	# Saltamos al inicio justo antes de llegar al silencio
	if posicion >= _duracion_total - _silencio_a_cortar - 0.02:
		print("Repitiendo | Cortando:", _silencio_a_cortar, "s de silencio")
		_reproductor.seek(0.0)


# Ahora recibe cuánto cortar para esa canción
func reproducir(ruta: String, cortar_silencio: float = 0.0) -> void:
	if ruta == _ruta_actual:
		# Si es la misma canción, actualizamos el valor por si cambió
		_silencio_a_cortar = cortar_silencio
		return

	if ruta.is_empty():
		print("Sin música asignada")
		_reproductor.volume_db = -80.0
		_ruta_actual = ""
		_silencio_a_cortar = 0.0
		return

	var nueva: AudioStream = load(ruta) as AudioStream
	if nueva:
		_ruta_actual = ruta
		_duracion_total = nueva.get_length()
		_silencio_a_cortar = cortar_silencio
		_reproductor.stream = nueva
		_reproductor.volume_db = 0.0
		_reproductor.play()
		print("Cargada:", ruta, " | Duración:", _duracion_total, "s | Cortar:", _silencio_a_cortar, "s")
	else:
		print("No se pudo cargar:", ruta)


func detener() -> void:
	_reproductor.stop()
	_ruta_actual = ""
	_silencio_a_cortar = 0.0
