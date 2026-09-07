extends Node2D
class_name PokedexPageForms

@onready var sprite_front: Sprite2D = $Front
@onready var sprite_back: Sprite2D = $Back
@onready var sprite_icon: Sprite2D = $Icon
@onready var label_specie: Label = $Specie
@onready var label_form: Label = $Form
@onready var arrow_up: Sprite2D = $Arrow_Up
@onready var arrow_down: Sprite2D = $Arrow_Down

var _species: PokemonDataStruct = null
var _form_index: int = 0
## Lista de vistas: base + forms (por ahora solo base)
var _forms: Array[PokemonDataStruct] = []


func setup(species: PokemonDataStruct, owned: bool = false) -> void:
	_species = species
	_form_index = 0
	_forms.clear()
	if _species == null:
		return

	_forms.append(_species)
	# Más adelante: añadir forms desde species.forms / SpeciesDB
	_actualizar_ui()
	_actualizar_flechas()


func _actualizar_ui() -> void:
	if _forms.is_empty():
		return
	var data: PokemonDataStruct = _forms[clampi(_form_index, 0, _forms.size() - 1)]

	if sprite_front:
		sprite_front.texture = data.front_sprite
	if sprite_back:
		sprite_back.texture = data.back_sprite
	if sprite_icon:
		sprite_icon.texture = data.icon_sprite
	if label_specie:
		label_specie.text = data.species_name
	if label_form:
		if _forms.size() <= 1:
			label_form.text = "Forma: Normal"
		else:
			label_form.text = "Forma: %d / %d" % [_form_index + 1, _forms.size()]


func _actualizar_flechas() -> void:
	var multi: bool = _forms.size() > 1
	if arrow_up:
		arrow_up.visible = multi
	if arrow_down:
		arrow_down.visible = multi


## Llamado desde el host si esta página está activa
func change_form(dir: int) -> void:
	if _forms.size() <= 1:
		return
	_form_index = wrapi(_form_index + dir, 0, _forms.size())
	_actualizar_ui()
