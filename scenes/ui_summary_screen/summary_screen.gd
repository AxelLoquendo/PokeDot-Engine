extends CanvasLayer
class_name SummaryScreen

signal summary_closed
signal party_index_changed(index: int)

var pokemon: PokemonInstance = null
var party: Array[PokemonInstance] = []
var party_index: int = 0
# -------- páginas de contenido (cuando las tengas) --------
@onready var pagina_0: SummaryPageInfo = $Page0
@onready var pagina_1: SummaryPageMemo = $Page1
@onready var pagina_2: SummaryPageSkills = $Page2

# -------- indicadores (hframes = 2) --------
@onready var page_info: Sprite2D = $Page_Info
@onready var page_memo: Sprite2D = $Page_Memo
@onready var page_baseivev: Sprite2D = $Page_BaseIvEv
@onready var page_skills: Sprite2D = $Page_Skills
@onready var page_moves: Sprite2D = $Page_Moves

var page_indicators: Array[Sprite2D] = []
var current_page: int = 0
const PAGE_COUNT: int = 5

# frame 0 = inactivo, frame 1 = activo
const FRAME_INACTIVE: int = 0
const FRAME_ACTIVE: int = 1

# Datos
@onready var poke_front: Sprite2D = $Front
@onready var ball: Sprite2D = $Info_0/Ball
@onready var poke_name: Label = $Info_0/Name
@onready var gender_label: Label = $Info_0/Gender
@onready var level_label: Label = $Info_0/Level
@onready var item_held: Sprite2D = $Info_1/Held
@onready var item_name: Label = $Info_1/Item/Name_Item

@onready var cry_poke: AudioStreamPlayer = $Cry

@export_group("Gender")
@export var genero_macho_color: Color = Color(0.0, 0.733, 1.0)
@export var genero_hembra_color: Color = Color(1.0, 0.35, 0.55)

@onready var cursor: AudioStreamPlayer = $Cursor  # opcional, si tienes sonido




func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_inicializar_indicadores()


func _reproducir_grito() -> void:
	if cry_poke == null or pokemon == null:
		return

	var species: PokemonDataStruct = pokemon.get_species()
	if species == null or species.cry == null:
		return

	cry_poke.stop()
	cry_poke.stream = species.cry
	cry_poke.play()

func _inicializar_indicadores() -> void:
	page_indicators = [
		page_info,
		page_memo,
		page_baseivev,
		page_skills,
		page_moves,
	]
	_actualizar_indicadores_pagina()


func _actualizar_indicadores_pagina() -> void:
	for i: int in range(page_indicators.size()):
		var sprite: Sprite2D = page_indicators[i]
		if sprite == null:
			continue
		sprite.frame = FRAME_ACTIVE if i == current_page else FRAME_INACTIVE


## Uso normal desde el party
func setup_from_party(party_list: Array[PokemonInstance], index: int) -> void:
	party = party_list
	party_index = clampi(index, 0, maxi(party.size() - 1, 0))
	_mostrar_pokemon_actual()


## Por si lo abres con un solo Pokémon
func setup(nuevo_pokemon: PokemonInstance) -> void:
	pokemon = nuevo_pokemon
	party = [nuevo_pokemon] if nuevo_pokemon else []
	party_index = 0
	_mostrar_pokemon_actual()


func _mostrar_pokemon_actual() -> void:
	if party.is_empty():
		return
	if party_index < 0 or party_index >= party.size():
		return

	pokemon = party[party_index]
	if pokemon == null:
		return

	_actualizar_ui()
	if pagina_0:
		pagina_0.setup(pokemon)
	if pagina_1:
		pagina_1.setup(pokemon)
	if pagina_2:
		pagina_2.setup(pokemon)

	party_index_changed.emit(party_index)
	_reproducir_grito()

func _cambiar_miembro(direccion: int) -> void:
	if party.size() <= 1:
		return

	var nuevo: int = party_index + direccion
	if nuevo < 0 or nuevo >= party.size():
		return  # sin wrap; si quieres loop, usa posmod

	if party[nuevo] == null:
		return

	party_index = nuevo
	_mostrar_pokemon_actual()

	if cursor:
		cursor.play()

func _actualizar_ui() -> void:
	_actualizar_sprite()
	_actualizar_nombre()
	_actualizar_nivel()
	_actualizar_genero()
	_actualizar_item()


func _actualizar_sprite() -> void:
	if poke_front == null:
		return
	var species: PokemonDataStruct = pokemon.get_species()
	if species == null:
		poke_front.texture = null
		return
	poke_front.texture = species.front_sprite


func _actualizar_nombre() -> void:
	if poke_name == null:
		return
	if poke_name.has_method("cambiar_texto"):
		poke_name.cambiar_texto(pokemon.get_display_name())
	else:
		poke_name.text = pokemon.get_display_name()


func _actualizar_nivel() -> void:
	if level_label == null:
		return
	level_label.text = " %d" % pokemon.level


func _actualizar_genero() -> void:
	if gender_label == null:
		return

	var texto: String = ""
	var color: Color = Color.WHITE

	match pokemon.gender:
		PokemonData.Gender.MALE:
			texto = "♂"
			color = genero_macho_color
		PokemonData.Gender.FEMALE:
			texto = "♀"
			color = genero_hembra_color
		_:
			texto = ""

	gender_label.text = texto
	if gender_label.label_settings != null:
		gender_label.label_settings = gender_label.label_settings.duplicate()
		gender_label.label_settings.font_color = color
	else:
		gender_label.add_theme_color_override("font_color", color)


func _actualizar_item() -> void:
	if item_name == null:
		return

	if pokemon.held_item == Items.ItemId.ITEM_NONE:
		item_name.text = "Ninguno"
		if item_held:
			item_held.texture = null
		return

	var data: ItemData = ItemDatabase.get_item(pokemon.held_item) if ItemDatabase else null
	if data:
		item_name.text = data.item_name
		if item_held:
			item_held.texture = data.icon
	else:
		item_name.text = str(pokemon.held_item)


func _input(event: InputEvent) -> void:
	if event.is_echo() or not event.is_pressed():
		return

	if event.is_action_pressed("buttonB"):
		get_viewport().set_input_as_handled()
		close()
		return

	if event.is_action_pressed("Up"):
		get_viewport().set_input_as_handled()
		_cambiar_miembro(-1)
		return

	if event.is_action_pressed("Down"):
		get_viewport().set_input_as_handled()
		_cambiar_miembro(1)
		return

	# Páginas del summary
	if event.is_action_pressed("Left"):
		get_viewport().set_input_as_handled()
		_cambiar_pagina(-1)
		return

	if event.is_action_pressed("Right"):
		get_viewport().set_input_as_handled()
		_cambiar_pagina(1)
		return


func _cambiar_pagina(direccion: int) -> void:
	var nueva: int = current_page + direccion
	if nueva < 0 or nueva >= PAGE_COUNT:
		return  # o posmod para loop

	current_page = nueva
	_actualizar_indicadores_pagina()
	_mostrar_pagina_actual()

	if cursor:
		cursor.play()


func _mostrar_pagina_actual() -> void:
	# Page0 (Info)
	if pagina_0:
		pagina_0.visible = (current_page == 0)

	# Page1 (Memo):
	if pagina_1:
		pagina_1.visible = (current_page == 1)
	# Page2 (Skills):
	if pagina_2:
		pagina_2.visible = (current_page == 2)

func close() -> void:
	summary_closed.emit()
	queue_free()
