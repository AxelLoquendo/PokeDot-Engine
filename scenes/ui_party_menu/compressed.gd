extends Label

# El límite en píxeles que el texto no debe superar (ej. el ancho del cuadro de texto GBA)
@export var ANCHO_MAXIMO: float = 60.0

# Cuánto espacio máximo permites que se "junten" las letras (en píxeles de pixel-art)
@export var MIN_SPACING_GLYPH: int = -2

func _ready() -> void:
	# Desactivamos el salto de línea automático
	autowrap_mode = TextServer.AUTOWRAP_OFF
	ajustar_texto_estilo_emerald()

func cambiar_texto(nuevo_texto: String) -> void:
	text = nuevo_texto
	ajustar_texto_estilo_emerald()

func ajustar_texto_estilo_emerald() -> void:
	# 1. Resetear todas las compresiones para medir el texto en su estado natural
	scale.x = 1.0
	add_theme_constant_override("spacing_glyph", 0)
	reset_size()
	
	# Si el texto entra perfectamente, no hacemos nada
	if size.x <= ANCHO_MAXIMO:
		return
		
	# 2. FASE 1 DE POKEEMERALD: Juntar las letras (reducir el tracking/spacing)
	# Vamos reduciendo el espacio entre letras pixel a pixel para ver si así cabe
	for i: int in range(-1, MIN_SPACING_GLYPH - 1, -1):
		add_theme_constant_override("spacing_glyph", i)
		reset_size()
		if size.x <= ANCHO_MAXIMO:
			return # ¡Pudo encajar solo juntando las letras!
			
	# 3. FASE 2 DE POKEEMERALD: Si aun así no cabe, aplastamos horizontalmente (escala)
	# Mantenemos las letras juntas y aplicamos el remanente con escala horizontal
	var ancho_con_letras_juntas: float = size.x
	scale.x = ANCHO_MAXIMO / ancho_con_letras_juntas
