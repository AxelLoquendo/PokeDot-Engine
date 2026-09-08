extends Node2D
class_name PokedexPageForms

signal form_changed(form_index: int, form_data: Dictionary)

@onready var sprite_front: Sprite2D = $Front
@onready var sprite_back: Sprite2D = $Back
@onready var sprite_icon: Sprite2D = $Icon
@onready var label_specie: Label = $Specie
@onready var label_form: Label = $Form
@onready var arrow_up: Sprite2D = $Arrow_Up
@onready var arrow_down: Sprite2D = $Arrow_Down

@export var icon_frame_time: float = 0.5
@export var arrow_frame_time: float = 0.08

var _base: PokemonDataStruct = null
var _form_index: int = 0
var _form_index_on_enter: int = 0
var _form_list: Array[Dictionary] = []
var form_select_mode: bool = false

var _icon_timer: float = 0.0
var _arrow_timer: float = 0.0


func _ready() -> void:
	set_process(true)
	_set_form_mode(false)


func setup(species: PokemonDataStruct, _owned: bool = false, initial_form_index: int = 0) -> void:
	_base = species
	_form_list.clear()
	_set_form_mode(false)

	if _base == null:
		return

	_form_list.append(_make_base_entry())

	if _base.forms != null:
		for form: PokemonFormData in _base.forms:
			if form == null:
				continue
			_form_list.append(_make_form_entry(form))

	_form_index = clampi(initial_form_index, 0, maxi(_form_list.size() - 1, 0))
	_form_index_on_enter = _form_index
	_actualizar_ui()


func _make_base_entry() -> Dictionary:
	return {
		"name": "Normal",
		"front": _base.front_sprite,
		"back": _base.back_sprite,
		"icon": _base.icon_sprite,
		"cry": _base.cry,
		"type_1": _base.type_1,
		"type_2": _base.type_2,
		"category_name": _base.category_name,
		"description": _base.description,
		"height": _base.height,
		"weight": _base.weight,
	}


func _make_form_entry(form: PokemonFormData) -> Dictionary:
	var fname: String = form.display_name
	if fname.is_empty():
		fname = str(form.form_id)

	var resolved: PokemonDataStruct = null
	if form.species_id != Species.SpeciesID.SPECIES_NONE:
		resolved = SpeciesDatabase.get_species(form.species_id)

	var t1: PokemonData.Type = _base.type_1
	var t2: PokemonData.Type = _base.type_2
	if form.override_types:
		t1 = form.type_1
		t2 = form.type_2
	elif resolved:
		t1 = resolved.type_1
		t2 = resolved.type_2

	var cat: String = _base.category_name
	var desc: String = _base.description
	var h: int = _base.height
	var w: int = _base.weight
	if form.override_pokedex:
		if not form.category_name.is_empty():
			cat = form.category_name
		if not form.description.is_empty():
			desc = form.description
		if form.height > 0:
			h = form.height
		if form.weight > 0:
			w = form.weight
	elif resolved:
		cat = resolved.category_name
		desc = resolved.description
		h = resolved.height
		w = resolved.weight

	var front: Texture2D = form.front_sprite
	var back: Texture2D = form.back_sprite
	var icon: Texture2D = form.icon_sprite
	var cry: AudioStream = form.cry
	if front == null and resolved:
		front = resolved.front_sprite
	if back == null and resolved:
		back = resolved.back_sprite
	if icon == null and resolved:
		icon = resolved.icon_sprite
	if cry == null and resolved:
		cry = resolved.cry
	if front == null:
		front = _base.front_sprite
	if back == null:
		back = _base.back_sprite
	if icon == null:
		icon = _base.icon_sprite
	if cry == null:
		cry = _base.cry

	return {
		"name": fname,
		"front": front,
		"back": back,
		"icon": icon,
		"cry": cry,
		"type_1": t1,
		"type_2": t2,
		"category_name": cat,
		"description": desc,
		"height": h,
		"weight": w,
	}


func _process(delta: float) -> void:
	if not visible:
		return
	_animate_icon(delta)
	if form_select_mode:
		_animate_arrows(delta)


func _animate_icon(delta: float) -> void:
	if sprite_icon == null or sprite_icon.texture == null:
		return
	if sprite_icon.hframes < 2:
		sprite_icon.hframes = 2
	_icon_timer += delta
	if _icon_timer >= icon_frame_time:
		_icon_timer = 0.0
		sprite_icon.frame = (sprite_icon.frame + 1) % sprite_icon.hframes


func _animate_arrows(delta: float) -> void:
	_arrow_timer += delta
	if _arrow_timer < arrow_frame_time:
		return
	_arrow_timer = 0.0
	_advance_arrow(arrow_up)
	_advance_arrow(arrow_down)


func _advance_arrow(arrow: Sprite2D) -> void:
	if arrow == null or not arrow.visible:
		return
	var total: int = maxi(arrow.hframes * maxi(arrow.vframes, 1), 1)
	if total <= 1:
		return
	arrow.frame = (arrow.frame + 1) % total


func enter_form_select() -> bool:
	if _form_list.size() <= 1:
		return false
	_form_index_on_enter = _form_index
	_set_form_mode(true)
	return true


func exit_form_select() -> void:
	_set_form_mode(false)


func is_form_select_mode() -> bool:
	return form_select_mode


## Solo preview: no confirma ni emite señal
func change_form(dir: int) -> void:
	if not form_select_mode:
		return
	if _form_list.size() <= 1:
		return
	_form_index = wrapi(_form_index + dir, 0, _form_list.size())
	_actualizar_ui()


## Confirmar con A
func confirm_form() -> void:
	if not form_select_mode:
		return
	if _form_list.is_empty():
		exit_form_select()
		return
	var f: Dictionary = _form_list[_form_index]
	form_changed.emit(_form_index, f)
	exit_form_select()


## Cancelar con B: restaura la forma que había al entrar al modo
func cancel_form_select_default() -> void:
	_form_index = clampi(_form_index_on_enter, 0, maxi(_form_list.size() - 1, 0))
	_actualizar_ui()
	exit_form_select()


func get_current_form_data() -> Dictionary:
	if _form_list.is_empty():
		return {}
	return _form_list[_form_index]


func _set_form_mode(enabled: bool) -> void:
	form_select_mode = enabled
	var show_arrows: bool = enabled and _form_list.size() > 1
	if arrow_up:
		arrow_up.visible = show_arrows
		arrow_up.frame = 0
	if arrow_down:
		arrow_down.visible = show_arrows
		arrow_down.frame = 0
	_arrow_timer = 0.0


func _actualizar_ui() -> void:
	if _form_list.is_empty():
		return
	var f: Dictionary = _form_list[_form_index]

	if sprite_front:
		sprite_front.texture = f["front"] as Texture2D
	if sprite_back:
		sprite_back.texture = f["back"] as Texture2D
	if sprite_icon:
		sprite_icon.texture = f["icon"] as Texture2D
		sprite_icon.hframes = 2
		sprite_icon.vframes = 1
		sprite_icon.frame = 0
		_icon_timer = 0.0

	if label_specie and _base:
		label_specie.text = _base.species_name
	if label_form:
		label_form.text = "Forma: %s" % str(f["name"])

	var show_arrows: bool = form_select_mode and _form_list.size() > 1
	if arrow_up:
		arrow_up.visible = show_arrows
	if arrow_down:
		arrow_down.visible = show_arrows
