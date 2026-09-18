@tool
extends VBoxContainer

class_name SpeciesGraphicsEditor

signal changed

const TEXTURE_FIELDS: Array[String] = [
	"front_sprite", "front_sprite_shiny", "back_sprite", "back_sprite_shiny",
	"icon_sprite", "overworld_scene", "overworld_scene_shiny",
	"front_sprite_female", "front_sprite_shiny_female", "back_sprite_female",
	"back_sprite_shiny_female", "icon_sprite_female", "overworld_scene_female",
	"overworld_scene_shiny_female"
]
const TEXTURE_LABELS: Dictionary = {
	"front_sprite": "Frontal", "front_sprite_shiny": "Frontal shiny",
	"back_sprite": "Trasero", "back_sprite_shiny": "Trasero shiny",
	"icon_sprite": "Icono", "overworld_scene": "Overworld / follower",
	"overworld_scene_shiny": "Overworld / follower shiny",
	"front_sprite_female": "Frontal hembra", "front_sprite_shiny_female": "Frontal shiny hembra",
	"back_sprite_female": "Trasero hembra", "back_sprite_shiny_female": "Trasero shiny hembra",
	"icon_sprite_female": "Icono hembra", "overworld_scene_female": "Overworld hembra",
	"overworld_scene_shiny_female": "Overworld shiny hembra"
}
const CARD_FILL: Color = Color("171d25")
const CARD_BORDER: Color = Color("34404d")
const TEXT: Color = Color("dce3eb")
const MUTED: Color = Color("91a0af")
const ACCENT: Color = Color("a7b7c8")

var current_species: PokemonDataStruct
var resource_pickers: Dictionary = {}
var previews: Dictionary = {}
var cry_picker: EditorResourcePicker
var cry_player: AudioStreamPlayer
var play_cry_button: Button
var front_offset_x: SpinBox
var front_offset_y: SpinBox
var back_offset_x: SpinBox
var back_offset_y: SpinBox

func set_species(species: PokemonDataStruct) -> void:
	current_species = species
	if is_inside_tree():
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	for child: Node in get_children():
		child.queue_free()
	resource_pickers.clear()
	previews.clear()
	var title: Label = Label.new()
	title.text = "Gráficos y audio"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", TEXT)
	add_child(title)
	var hint: Label = Label.new()
	hint.text = "Cada tarjeta muestra el recurso asignado. Vacío significa que no hay override en esta especie."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MUTED)
	add_child(hint)
	_add_group("Sprites de batalla y Pokédex", _field_slice(0, 7))
	_add_group("Variantes femeninas opcionales", _field_slice(7, 14))
	_add_cry_section()
	_add_offset_section()

func _field_slice(start_index: int, end_index: int) -> Array[String]:
	var result: Array[String] = []
	for index: int in range(start_index, end_index):
		result.append(TEXTURE_FIELDS[index])
	return result

func _add_group(title_text: String, fields_to_add: Array[String]) -> void:
	var title: Label = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", ACCENT)
	add_child(title)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	add_child(grid)
	for field_name: String in fields_to_add:
		grid.add_child(_make_texture_card(field_name))

func _make_texture_card(field_name: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 176)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = CARD_FILL
	style.border_color = CARD_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	card.add_theme_stylebox_override("panel", style)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 5)
	card.add_child(rows)
	var heading: HBoxContainer = HBoxContainer.new()
	rows.add_child(heading)
	var label: Label = Label.new()
	label.text = str(TEXTURE_LABELS.get(field_name, field_name))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", TEXT)
	heading.add_child(label)
	var preview: TextureRect = TextureRect.new()
	preview.custom_minimum_size = Vector2(0, 92)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = _get_texture(field_name)
	preview.tooltip_text = "Vista previa de " + label.text
	rows.add_child(preview)
	previews[field_name] = preview
	var picker: EditorResourcePicker = EditorResourcePicker.new()
	picker.base_type = "Texture2D"
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.edited_resource = _get_texture(field_name)
	picker.resource_changed.connect(_on_texture_changed.bind(field_name))
	rows.add_child(picker)
	resource_pickers[field_name] = picker
	var state: Label = Label.new()
	state.name = "AssignmentState"
	state.text = "Asignado aquí" if picker.edited_resource != null else "Sin recurso — usa el valor del runtime si corresponde"
	state.add_theme_color_override("font_color", MUTED)
	rows.add_child(state)
	return card

func _add_cry_section() -> void:
	var title: Label = Label.new()
	title.text = "Cry"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", ACCENT)
	add_child(title)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	var label: Label = Label.new()
	label.text = "Audio de combate"
	label.custom_minimum_size = Vector2(145, 0)
	row.add_child(label)
	cry_picker = EditorResourcePicker.new()
	cry_picker.base_type = "AudioStream"
	cry_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cry_picker.edited_resource = current_species.cry if current_species else null
	cry_picker.resource_changed.connect(_on_cry_changed)
	row.add_child(cry_picker)
	play_cry_button = Button.new()
	play_cry_button.text = "Reproducir"
	play_cry_button.disabled = cry_picker.edited_resource == null
	play_cry_button.pressed.connect(_on_play_cry_pressed)
	row.add_child(play_cry_button)
	var clear_button: Button = Button.new()
	clear_button.text = "Limpiar"
	clear_button.pressed.connect(_on_clear_cry_pressed)
	row.add_child(clear_button)
	cry_player = AudioStreamPlayer.new()
	add_child(cry_player)

func _add_offset_section() -> void:
	var title: Label = Label.new()
	title.text = "Offsets de batalla"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", ACCENT)
	add_child(title)
	var hint: Label = Label.new()
	hint.text = "Unidades lógicas. Escala actual: %d px por unidad." % int(PokemonDataStruct.BATTLE_OFFSET_SCALE)
	hint.add_theme_color_override("font_color", MUTED)
	add_child(hint)
	var front_values: Vector2 = current_species.front_sprite_offset if current_species else Vector2.ZERO
	var back_values: Vector2 = current_species.back_sprite_offset if current_species else Vector2.ZERO
	front_offset_x = _make_offset_spin(front_values.x)
	front_offset_y = _make_offset_spin(front_values.y)
	back_offset_x = _make_offset_spin(back_values.x)
	back_offset_y = _make_offset_spin(back_values.y)
	_add_offset_row("Frontal", front_offset_x, front_offset_y)
	_add_offset_row("Trasero", back_offset_x, back_offset_y)

func _add_offset_row(name: String, x_spin: SpinBox, y_spin: SpinBox) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_child(_make_label(name + " X"))
	row.add_child(x_spin)
	row.add_child(_make_label("Y"))
	row.add_child(y_spin)
	add_child(row)
	x_spin.value_changed.connect(_on_offset_changed)
	y_spin.value_changed.connect(_on_offset_changed)

func _make_offset_spin(value: float) -> SpinBox:
	var spin: SpinBox = SpinBox.new()
	spin.min_value = -20
	spin.max_value = 20
	spin.step = 0.125
	spin.value = value
	spin.custom_minimum_size = Vector2(78, 0)
	return spin

func _make_label(value: String) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.custom_minimum_size = Vector2(70, 0)
	return label

func _get_texture(field_name: String) -> Texture2D:
	if current_species == null:
		return null
	return current_species.get(field_name) as Texture2D

func _on_texture_changed(resource: Resource, field_name: String) -> void:
	var preview: TextureRect = previews.get(field_name) as TextureRect
	if preview != null:
		preview.texture = resource as Texture2D
	var picker: EditorResourcePicker = resource_pickers.get(field_name) as EditorResourcePicker
	if picker != null:
		var card: Control = picker.get_parent() as Control
		var state: Label = card.get_node_or_null("AssignmentState") as Label
		if state != null:
			state.text = "Asignado aquí" if resource != null else "Sin recurso — usa el valor del runtime si corresponde"
	changed.emit()

func _on_cry_changed(resource: Resource) -> void:
	if play_cry_button != null:
		play_cry_button.disabled = resource == null
	changed.emit()

func _on_clear_cry_pressed() -> void:
	if cry_picker != null:
		cry_picker.edited_resource = null
		_on_cry_changed(null)

func _on_play_cry_pressed() -> void:
	if cry_picker != null and cry_picker.edited_resource is AudioStream and cry_player != null:
		cry_player.stream = cry_picker.edited_resource as AudioStream
		cry_player.play()

func _on_offset_changed(_value: float) -> void:
	changed.emit()

func apply_to_species(species: PokemonDataStruct) -> void:
	if species == null:
		return
	for field_name: String in TEXTURE_FIELDS:
		var picker: EditorResourcePicker = resource_pickers.get(field_name) as EditorResourcePicker
		if picker != null:
			species.set(field_name, picker.edited_resource as Texture2D)
	if cry_picker != null:
		species.cry = cry_picker.edited_resource as AudioStream
	if front_offset_x != null and front_offset_y != null:
		species.front_sprite_offset = Vector2(front_offset_x.value, front_offset_y.value)
	if back_offset_x != null and back_offset_y != null:
		species.back_sprite_offset = Vector2(back_offset_x.value, back_offset_y.value)
