@tool
extends VBoxContainer

class_name PokemonFormsEditor

signal changed

const FORM_EDITOR_SCRIPT := preload("res://addons/species_editor/controls/form_editor.gd")

var current_species: PokemonDataStruct
var available_species: Array[PokemonDataStruct] = []
var forms: Array[PokemonFormData] = []
var form_selector: OptionButton
var form_editor: PokemonFormEditor
var selected_index: int = -1
var rebuilding: bool = false

func set_available_species(values: Array[PokemonDataStruct]) -> void:
	available_species = values
	if form_editor != null:
		form_editor.set_available_species(values)

func set_species(species: PokemonDataStruct) -> void:
	current_species = species
	forms.clear()
	if species != null:
		forms = species.forms.duplicate(true)
		for form: PokemonFormData in forms:
			if form != null and form.base_species_id == Species.SpeciesID.SPECIES_NONE:
				form.base_species_id = species.species_id
	if is_inside_tree():
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	rebuilding = true
	for child: Node in get_children():
		child.queue_free()
	form_selector = null
	form_editor = null
	selected_index = -1

	var header: HBoxContainer = HBoxContainer.new()
	var title: Label = Label.new()
	title.text = "Formas y variantes"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var add_button: Button = Button.new()
	add_button.text = "+ Añadir forma"
	add_button.pressed.connect(_add_form)
	header.add_child(add_button)
	add_child(header)

	if forms.is_empty():
		var empty: Label = Label.new()
		empty.text = "Esta especie todavía no tiene variantes."
		add_child(empty)
		rebuilding = false
		return

	var selector_row: HBoxContainer = HBoxContainer.new()
	var selector_label: Label = Label.new()
	selector_label.text = "Forma seleccionada"
	selector_label.custom_minimum_size = Vector2(180, 0)
	selector_row.add_child(selector_label)
	form_selector = OptionButton.new()
	form_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for index: int in range(forms.size()):
		form_selector.add_item(_form_label(forms[index]), index)
	form_selector.item_selected.connect(_select_form)
	selector_row.add_child(form_selector)
	add_child(selector_row)

	var action_row: HBoxContainer = HBoxContainer.new()
	var duplicate_button: Button = Button.new()
	duplicate_button.text = "Duplicar forma"
	duplicate_button.pressed.connect(_duplicate_form)
	action_row.add_child(duplicate_button)
	var delete_button: Button = Button.new()
	delete_button.text = "Eliminar forma"
	delete_button.pressed.connect(_delete_form)
	action_row.add_child(delete_button)
	add_child(action_row)

	form_editor = FORM_EDITOR_SCRIPT.new()
	form_editor.set_available_species(available_species)
	form_editor.changed.connect(_on_form_changed)
	add_child(form_editor)
	selected_index = 0
	form_selector.select(0)
	form_editor.load_form(forms[0])
	rebuilding = false

func _form_label(form: PokemonFormData) -> String:
	var id_text := "ID pendiente" if form.species_id == Species.SpeciesID.SPECIES_NONE else str(int(form.species_id))
	return "[%s] %s (%s)" % [id_text, form.get_display_name(), str(form.form_id)]

func _select_form(index: int) -> void:
	if rebuilding or index < 0 or index >= forms.size():
		return
	_apply_current_form()
	selected_index = index
	form_editor.load_form(forms[index])
	changed.emit()

func _apply_current_form() -> void:
	if form_editor != null and selected_index >= 0 and selected_index < forms.size():
		form_editor.apply_to_form(forms[selected_index])

func _add_form() -> void:
	_apply_current_form()
	var form: PokemonFormData = PokemonFormData.new()
	# El ID debe corresponder a una constante de species.gd. Se deja en NONE
	# para obligar a elegir un ID reservado y evitar duplicados accidentales.
	form.species_id = Species.SpeciesID.SPECIES_NONE
	form.form_id = StringName("form_%d" % forms.size())
	form.display_name = "Nueva forma"
	if current_species != null:
		form.base_species_id = current_species.species_id
	forms.append(form)
	_rebuild()
	changed.emit()

func _duplicate_form() -> void:
	if selected_index < 0 or selected_index >= forms.size():
		return
	_apply_current_form()
	var copy: PokemonFormData = forms[selected_index].duplicate(true) as PokemonFormData
	# Una copia no puede conservar el mismo ID real.
	copy.species_id = Species.SpeciesID.SPECIES_NONE
	copy.form_id = StringName("%s_copy" % str(copy.form_id))
	copy.display_name = "%s Copy" % copy.get_display_name()
	forms.append(copy)
	_rebuild()
	changed.emit()

func _delete_form() -> void:
	if selected_index < 0 or selected_index >= forms.size():
		return
	forms.remove_at(selected_index)
	_rebuild()
	changed.emit()

func _on_form_changed() -> void:
	if not rebuilding:
		changed.emit()

func get_forms() -> Array[PokemonFormData]:
	_apply_current_form()
	return forms.duplicate(true)
