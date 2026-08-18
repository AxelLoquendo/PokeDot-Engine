extends Node2D  
  
@export var velocidad: float = 40.0  
@onready var sprites: Array[Sprite2D] = [$".", $"../Fondo2"]  
var alto: float = 256.0 * 2.0  # 512  
  
func _ready() -> void:  
	sprites[0].position.y = 256  
	sprites[1].position.y = 256 - alto  # exactamente "alto" de separación, centrado en 256  
  
func _process(delta: float) -> void:  
	for s: Sprite2D in sprites:  
		s.position.y += velocidad * delta  
		if s.position.y >= 256 + alto:      # relativo al centro de pantalla (256), no a 0  
			s.position.y -= alto * 2
