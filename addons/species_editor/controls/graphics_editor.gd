@tool
extends VBoxContainer

class_name SpeciesGraphicsEditor

signal changed

const TEXTURE_FIELDS: Array[String] = [
	"front_sprite",
	"front_sprite_shiny",
	"back_sprite",
	"back_sprite_shiny",
	"icon_sprite",
	"overworld_scene",
	"overworld_scene_shiny",
	"front_sprite_female",
	"front_sprite_shiny_female",
	"back_sprite_female",
	"back_sprite_shiny_female",
	"icon_sprite_female",
	"overworld_scene_female",
	"overworld_scene_shiny_female",
]

const TEXTURE_LABELS: Dictionary = {
	"front_sprite": "Frontal",
	"front_sprite_shiny": "Frontal shiny",
	"back_sprite": "Trasero",
	"back_sprite_shiny": "Trasero shiny",
	"icon_sprite": "Icono",
	"overworld_scene": "Overworld / follower",
	"overworld_scene_shiny": "Overworld / follower shiny",
	"front_sprite_female": "Frontal hembra",
	"front_sprite_shiny_female": "Frontal shiny hembra",
	"back_sprite_female": "Trasero hembra",
	"back_sprite_shiny_female": "Trasero shiny hembra",
	"icon_sprite_female": "Icono hembra",
	"overworld_scene_female": "Overworld hembra",
	"overworld_scene_shiny_female": "Overworld shiny hembra",
}

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
	cry_picker = null
	play_cry_button = null
	front_offset_x = null
	front_offset_y = null
	back_offset_x = null
	back_offset_y = null

	var title: Label = Label.new()
	title.text = "Sprites, cry y posiciones"
	title.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	add_child(title)

	var hint: Label = Label.new()
	hint.text = "Puedes seleccionar recursos desde el FileSystem o arrastrarlos al selector."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	add_child(hint)

	var normal_title: Label = Label.new()
	normal_title.text = "Sprites normales"
	normal_title.add_theme_font_size_override("font_size", 13)
	add_child(normal_title)
	for field_name: String in TEXTURE_FIELDS.slice(0, 7):
		_add_texture_row(field_name)

	var female_title: Label = Label.new()
	female_title.text = "Sprites femeninos (opcionales)"
	female_title.add_theme_font_size_override("font_size", 13)
	add_child(female_title)
	for field_name: String in TEXTURE_FIELDS.slice(7, 14):
		_add_texture_row(field_name)

	_add_cry_row()
	_add_offset_section()

func _add_texture_row(field_name: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	var label: Label = Label.new()
	label.text = str(TEXTURE_LABELS.get(field_name, field_name))
	label.custom_minimum_size = Vector2(145, 0)
	row.add_child(label)

	var picker: EditorResourcePicker = EditorResourcePicker.new()
	picker.base_type = "Texture2D"
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value: Texture2D = _get_texture(field_name)
	picker.edited_resource = value
	picker.resource_changed.connect(_on_texture_changed.bind(field_name))
	row.add_child(picker)
	resource_pickers[field_name] = picker

	var preview: TextureRect = TextureRect.new()
	preview.custom_minimum_size = Vector2(48, 48)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_END
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = value
	row.add_child(preview)
	previews[field_name] = preview

func _add_cry_row() -> void:
	var title: Label = Label.new()
	title.text = "Cry"
	title.add_theme_font_size_override("font_size", 13)
	add_child(title)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
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
	play_cry_button.text = "▶"
	play_cry_button.tooltip_text = "Reproducir cry"
	play_cry_button.disabled = current_species == null or current_species.cry == null
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
	add_child(title)

	var front_values: Vector2 = current_species.front_sprite_offset if current_species else Vector2.ZERO
	var back_values: Vector2 = current_species.back_sprite_offset if current_species else Vector2.ZERO
	var scale_hint: Label = Label.new()
	scale_hint.text = "Unidades lógicas. Escala actual: %d px por unidad." % int(PokemonDataStruct.BATTLE_OFFSET_SCALE)
	scale_hint.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	add_child(scale_hint)

	var front_row: HBoxContainer = HBoxContainer.new()
	front_row.add_child(_make_label("Frontal X"))
	front_offset_x = _make_offset_spin(front_values.x)
	front_offset_x.value_changed.connect(_on_offset_changed)
	front_row.add_child(front_offset_x)
	front_row.add_child(_make_label("Y"))
	front_offset_y = _make_offset_spin(front_values.y)
	front_offset_y.value_changed.connect(_on_offset_changed)
	front_row.add_child(front_offset_y)
	add_child(front_row)

	var back_row: HBoxContainer = HBoxContainer.new()
	back_row.add_child(_make_label("Trasero X"))
	back_offset_x = _make_offset_spin(back_values.x)
	back_offset_x.value_changed.connect(_on_offset_changed)
	back_row.add_child(back_offset_x)
	back_row.add_child(_make_label("Y"))
	back_offset_y = _make_offset_spin(back_values.y)
	back_offset_y.value_changed.connect(_on_offset_changed)
	back_row.add_child(back_offset_y)
	add_child(back_row)

func _make_offset_spin(value: float) -> SpinBox:
	var spin: SpinBox = SpinBox.new()
	spin.min_value = -20
	spin.max_value = 20
	spin.step = 0.125
	spin.value = value
	spin.custom_minimum_size = Vector2(78, 0)
	return spin

func _make_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
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
	changed.emit()

func _on_cry_changed(resource: Resource) -> void:
	if play_cry_button != null:
		play_cry_button.disabled = resource == null
	changed.emit()

func _on_clear_cry_pressed() -> void:
	if cry_picker != null:
		cry_picker.edited_resource = null
		if play_cry_button != null:
			play_cry_button.disabled = true
		changed.emit()

func _on_play_cry_pressed() -> void:
	if cry_picker == null or cry_picker.edited_resource == null or cry_player == null:
		return
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
