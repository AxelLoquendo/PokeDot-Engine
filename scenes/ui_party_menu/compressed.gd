extends Label

# ============================================================
# CONFIGURACIÓN
# ============================================================

@export_group("Texto Emerald")

## Ancho máximo permitido para el texto.
@export var ancho_maximo: float = 60.0

## Espaciado mínimo entre glifos.
@export var min_spacing_glyph: int = -2


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	# Desactivar word wrap.
	autowrap_mode = TextServer.AUTOWRAP_OFF

	# Aplicar configuración inicial.
	ajustar_texto_estilo_emerald()


# ============================================================
# CAMBIAR TEXTO
# ============================================================

func cambiar_texto(nuevo_texto: String) -> void:
	text = nuevo_texto
	ajustar_texto_estilo_emerald()


# ============================================================
# AJUSTAR TEXTO
# ============================================================

func ajustar_texto_estilo_emerald() -> void:
	# --------------------------------------------------------
	# Restaurar estado original antes de volver a calcular.
	# --------------------------------------------------------

	scale.x = 1.0
	add_theme_constant_override("spacing_glyph", 0)

	# --------------------------------------------------------
	# Si no hay texto, no hay nada que ajustar.
	# --------------------------------------------------------

	if text.is_empty():
		return

	# --------------------------------------------------------
	# Obtener fuente y tamaño actuales del Label.
	# --------------------------------------------------------

	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")

	if font == null:
		return

	# --------------------------------------------------------
	# Medir el texto en su estado natural.
	# --------------------------------------------------------

	var ancho_natural: float = font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x

	# --------------------------------------------------------
	# Si ya cabe, no hacemos nada.
	# --------------------------------------------------------

	if ancho_natural <= ancho_maximo:
		return

	# ========================================================
	# FASE 1
	# Reducir spacing_glyph
	# ========================================================

	for spacing: int in range(-1, min_spacing_glyph - 1, -1):

		add_theme_constant_override(
			"spacing_glyph",
			spacing
		)

		var ancho_comprimido: float = _medir_texto(spacing)

		if ancho_comprimido <= ancho_maximo:
			return

	# ========================================================
	# FASE 2
	# Escala horizontal
	# ========================================================

	# Medimos nuevamente con el spacing mínimo aplicado.
	var ancho_final: float = _medir_texto(min_spacing_glyph)

	if ancho_final <= 0.0:
		return

	scale.x = ancho_maximo / ancho_final


# ============================================================
# MEDIR TEXTO
# ============================================================

func _medir_texto(spacing: int) -> float:
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")

	if font == null:
		return 0.0

	# Ancho base del texto.
	var ancho: float = font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x

	# Aplicar el espaciado entre glifos.
	#
	# Hay N-1 espacios entre N caracteres.
	var cantidad_glyphs: int = text.length()

	if cantidad_glyphs > 1:
		ancho += spacing * (cantidad_glyphs - 1)

	return maxf(ancho, 0.0)
