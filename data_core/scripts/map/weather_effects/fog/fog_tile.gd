extends Node2D
class_name FogTile

var weather: FogWeather
var grid_position: Vector2i = Vector2i.ZERO

var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready() and sprite:
			sprite.texture = value

var escala_tile: Vector2 = Vector2.ONE:
	set(value):
		escala_tile = value
		if is_node_ready() and sprite:
			sprite.scale = value

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	z_index = 3001
	sprite.centered = false
	sprite.texture = texture
	sprite.scale = escala_tile
	sprite.modulate.a = 0.0


func _process(_delta: float) -> void:
	if weather == null:
		return
	sprite.modulate.a = weather.intensidad
