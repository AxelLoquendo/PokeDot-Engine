extends Control
class_name PartySlot


# ============================================================
# REFERENCIAS
# ============================================================
@export var held_marker: Texture2D
@onready var sprite_icon: Sprite2D = $Icon
@onready var label_genero: Label = $Genero

@onready var label_name: Label = $Name
@onready var label_level: Label = $Level
@onready var label_hp: Label = $HP

@onready var hp_bar: ColorRect = $HpBar

@onready var boton_caja: TextureButton = $Caja

@onready var sprite_estado: Sprite2D = $Status
@onready var sprite_objeto: Sprite2D = $Held

@export_group("Caja")

@export var caja_chico_normal: Texture2D
@export var caja_chico_focused: Texture2D

@export var caja_chica_normal: Texture2D
@export var caja_chica_focused: Texture2D

# ============================================================
# POKÉMON
# ============================================================

var pokemon: PokemonInstance = null


# ============================================================
# CONFIGURACIÓN HP
# ============================================================

var hp_bar_ancho_maximo: float = 0.0


@export_group("HP Bar")

@export var hp_color_normal: Color = Color.GREEN
@export var hp_color_low: Color = Color.YELLOW
@export var hp_color_critical: Color = Color.RED

@export_group("Gender")

@export var genero_macho_color: Color = Color(0.0, 0.733, 1.0)
@export var genero_hembra_color: Color = Color(0.95, 0.723, 1.0, 1.0)

# ============================================================
# ANIMACIÓN DEL ICONO
# ============================================================

@export_group("Icon Animation")

@export var icon_frame_time: float = 0.5

var icon_frame_timer: float = 0.0

# ============================================================
# READY
# ============================================================

func _ready() -> void:
	if hp_bar != null:
		hp_bar_ancho_maximo = hp_bar.size.x

	if boton_caja != null:
		boton_caja.focus_mode = Control.FOCUS_ALL

	if sprite_estado != null:
		sprite_estado.visible = false

	if sprite_objeto != null:
		sprite_objeto.visible = false

func configurar_caja_genero(es_chica: bool) -> void:
	if boton_caja == null:
		return

	if es_chica:
		boton_caja.texture_normal = caja_chica_normal
		boton_caja.texture_focused = caja_chica_focused
	else:
		boton_caja.texture_normal = caja_chico_normal
		boton_caja.texture_focused = caja_chico_focused

func _process(delta: float) -> void:
	if pokemon == null:
		return

	if sprite_icon == null:
		return

	icon_frame_timer += delta

	if icon_frame_timer >= icon_frame_time:
		icon_frame_timer = 0.0

		sprite_icon.frame = 1 - sprite_icon.frame

func enfocar() -> void:

	if boton_caja == null:
		return

	boton_caja.grab_focus()

func quitar_focus() -> void:

	if boton_caja == null:
		return

	if boton_caja.has_focus():
		boton_caja.release_focus()

# ============================================================
# ASIGNAR POKÉMON
# ============================================================

func set_pokemon(
	nuevo_pokemon: PokemonInstance
) -> void:

	pokemon = nuevo_pokemon

	_actualizar_ui()


# ============================================================
# LIMPIAR SLOT
# ============================================================

func _limpiar() -> void:

	pokemon = null


	if sprite_icon != null:

		sprite_icon.texture = null

	if sprite_objeto != null:
		sprite_objeto.visible = false
		sprite_objeto.texture = null

	if label_genero != null:

		label_genero.text = ""
		label_genero.self_modulate = Color.WHITE


	if label_name != null:

		label_name.text = ""


	if label_level != null:

		label_level.text = ""


	if label_hp != null:

		label_hp.text = ""


	if hp_bar != null:

		hp_bar.size.x = 0


# ============================================================
# ACTUALIZAR UI
# ============================================================

func _actualizar_ui() -> void:

	if pokemon == null:

		_limpiar()

		return


	_actualizar_nombre()
	_actualizar_nivel()
	_actualizar_hp()
	_actualizar_icono()
	_actualizar_genero()
	_actualizar_held()


# ============================================================
# NOMBRE
# ============================================================

func _actualizar_nombre() -> void:

	if label_name == null:
		return


	label_name.cambiar_texto(
		pokemon.get_display_name()
	)


# ============================================================
# NIVEL
# ============================================================

func _actualizar_nivel() -> void:

	if label_level == null:
		return


	label_level.text = (
		"Nv.%d" % pokemon.level
	)


# ============================================================
# HP
# ============================================================

func _actualizar_hp() -> void:
	if pokemon == null:
		return

	# Texto
	if label_hp != null:
		label_hp.text = "%d/%d" % [pokemon.current_hp, pokemon.max_hp]

	# Barra
	if hp_bar == null:
		return

	if hp_bar_ancho_maximo <= 0.0:
		hp_bar_ancho_maximo = hp_bar.size.x

	var percent: float = pokemon.get_hp_percent()
	hp_bar.size.x = hp_bar_ancho_maximo * percent

	# Color según porcentaje
	if percent > 0.5:
		hp_bar.color = hp_color_normal
	elif percent > 0.2:
		hp_bar.color = hp_color_low
	else:
		hp_bar.color = hp_color_critical

# ============================================================
# ICONO
# ============================================================

func _actualizar_icono() -> void:
	if sprite_icon == null:
		return

	var species: PokemonDataStruct = pokemon.get_species()

	if species == null:
		sprite_icon.texture = null
		return

	sprite_icon.texture = species.icon_sprite
	sprite_icon.hframes = 2
	sprite_icon.vframes = 1
	sprite_icon.frame = 0
	icon_frame_timer = 0.0

# ============================================================
# GÉNERO
# ============================================================

func _actualizar_genero() -> void:
	if label_genero == null:
		return

	var color: Color = Color.WHITE
	var texto: String = ""

	match pokemon.gender:
		PokemonData.Gender.MALE:
			texto = "♂"
			color = genero_macho_color
		PokemonData.Gender.FEMALE:
			texto = "♀"
			color = genero_hembra_color
		_:
			texto = ""
			color = Color.WHITE

	label_genero.text = texto

	# 1) Si usa LabelSettings (lo más común cuando "no cambia")
	if label_genero.label_settings != null:
		# Duplicar para no compartir el resource entre slots
		label_genero.label_settings = label_genero.label_settings.duplicate()
		label_genero.label_settings.font_color = color
	else:
		# 2) Label normal
		label_genero.add_theme_color_override("font_color", color)

	label_genero.modulate = Color.WHITE
	label_genero.self_modulate = Color.WHITE

	print(pokemon.get_display_name(), " gender=", pokemon.gender, " color=", color)

func _actualizar_held() -> void:
	if sprite_objeto == null:
		return
	var tiene: bool = (
		pokemon != null
		and pokemon.held_item != Items.ItemId.ITEM_NONE
	)
	sprite_objeto.visible = tiene
	if tiene and held_marker:
		sprite_objeto.texture = held_marker

func clear() -> void:

	_limpiar()
