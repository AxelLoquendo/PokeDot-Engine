extends CanvasLayer
class_name PokedexEntryUI

signal entry_closed

@onready var pages_root: Node2D = $Pages
@onready var cry_player: AudioStreamPlayer = $Cry
@onready var tab_info: Sprite2D = $Info
@onready var tab_area: Sprite2D = $Area
@onready var tab_forms: Sprite2D = $Forms
@onready var tab_data: Sprite2D = $Data
@onready var arrow_left: Sprite2D = $Arrow_Left
@onready var arrow_right: Sprite2D = $Arrow_Right

var _pages: Array[Node2D] = []
var _tabs: Array[Sprite2D] = []
var _page_index: int = 0
var _species: PokemonDataStruct = null
var _owned: bool = false
var _active: bool = false

var _entries: Array[Dictionary] = []
var _entry_index: int = 0
var _pokedex: PokedexData = null
var _form_selection: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pokedex_entry")
	_tabs = [tab_info, tab_area, tab_forms, tab_data]
	_collect_pages()
	_show_page(0)


func _collect_pages() -> void:
	_pages.clear()
	if pages_root == null:
		pages_root = get_node_or_null("Pages") as Node2D
	if pages_root == null:
		push_error("PokedexEntryUI: no existe nodo Pages")
		return
	for c: Node in pages_root.get_children():
		if c is Node2D:
			_pages.append(c as Node2D)
	_pages.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.name.naturalnocasecmp_to(b.name) < 0
	)


func setup(
	species_id: int,
	pokedex: PokedexData,
	entries: Array[Dictionary] = [],
	entry_index: int = 0
) -> void:
	if _pages.is_empty():
		_collect_pages()
	_pokedex = pokedex
	_entries = entries
	_entry_index = entry_index
	_active = true
	_page_index = 0
	_load_species(species_id)
	_show_page(0)
	_play_cry()


func set_selected_form_index(species_id: int, form_index: int) -> void:
	_form_selection[species_id] = form_index


func get_selected_form_index(species_id: int) -> int:
	return int(_form_selection.get(species_id, 0))


func play_cry_stream(stream: AudioStream) -> void:
	if cry_player == null or stream == null:
		return
	cry_player.stop()
	cry_player.stream = stream
	cry_player.play()


func _load_species(species_id: int) -> void:
	_species = SpeciesDatabase.get_species(species_id as Species.SpeciesID)
	_owned = _pokedex != null and _pokedex.is_owned(species_id)
	_refresh_pages()


func _refresh_pages() -> void:
	if _species == null:
		return
	var sid: int = int(_species.species_id)
	var form_i: int = get_selected_form_index(sid)

	for p: Node2D in _pages:
		if not p.has_method("setup"):
			continue
		if p is PokedexPageForms:
			p.call("setup", _species, _owned, form_i)
		else:
			p.call("setup", _species, _owned)

	_connect_forms_signal()
	_apply_stored_form_to_info()


func _connect_forms_signal() -> void:
	var forms_page: Node2D = _get_forms_page()
	if forms_page == null:
		return
	if forms_page.has_signal("form_changed"):
		if forms_page.form_changed.is_connected(_on_form_changed):
			forms_page.form_changed.disconnect(_on_form_changed)
		forms_page.form_changed.connect(_on_form_changed)


func _on_form_changed(form_index: int, form_data: Dictionary) -> void:
	if _species == null:
		return
	var sid: int = int(_species.species_id)
	set_selected_form_index(sid, form_index)

	var cry: AudioStream = form_data.get("cry") as AudioStream
	if cry:
		play_cry_stream(cry)
	elif _species.cry:
		play_cry_stream(_species.cry)

	_apply_form_display(form_data)

	var list: Node = get_tree().get_first_node_in_group("pokedex_list")
	if list and list.has_method("set_form_override"):
		list.call("set_form_override", sid, form_index, form_data)


func _apply_stored_form_to_info() -> void:
	if _species == null:
		return
	var sid: int = int(_species.species_id)
	var form_i: int = get_selected_form_index(sid)
	if form_i <= 0:
		return
	var forms_page: Node2D = _get_forms_page()
	if forms_page is PokedexPageForms:
		var data: Dictionary = (forms_page as PokedexPageForms).get_current_form_data()
		if not data.is_empty():
			_apply_form_display(data)


func _apply_form_display(form_data: Dictionary) -> void:
	if form_data.is_empty() or _pages.is_empty():
		return
	var page0: Node2D = _pages[0]
	if page0.has_method("apply_form_display"):
		page0.call("apply_form_display", form_data)


func _show_page(index: int) -> void:
	if _pages.is_empty():
		_collect_pages()
	if _pages.is_empty():
		return

	var forms_page: Node2D = _get_forms_page()
	if forms_page and forms_page.has_method("exit_form_select"):
		forms_page.call("exit_form_select")

	_page_index = clampi(index, 0, _pages.size() - 1)
	for i: int in range(_pages.size()):
		_pages[i].visible = (i == _page_index)
		if _pages[i].visible:
			_pages[i].show()

	_update_tabs()
	_update_arrows()


func _update_tabs() -> void:
	for i: int in range(_tabs.size()):
		var tab: Sprite2D = _tabs[i]
		if tab == null:
			continue
		tab.frame = 1 if i == _page_index else 0


func _update_arrows() -> void:
	if arrow_left:
		arrow_left.visible = _page_index > 0
	if arrow_right:
		arrow_right.visible = _page_index < _pages.size() - 1


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_echo():
		return

	var forms_page: Node2D = _get_forms_page()
	var in_form_mode: bool = (
		forms_page != null
		and forms_page.has_method("is_form_select_mode")
		and bool(forms_page.call("is_form_select_mode"))
	)

	if event.is_action_pressed("buttonB"):
		if in_form_mode and forms_page:
			if forms_page.has_method("cancel_form_select_default"):
				forms_page.call("cancel_form_select_default")
			else:
				forms_page.call("exit_form_select")
		else:
			_close()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("buttonA"):
		if _page_index == 2 and forms_page:
			if in_form_mode and forms_page.has_method("confirm_form"):
				forms_page.call("confirm_form")
			elif forms_page.has_method("enter_form_select"):
				forms_page.call("enter_form_select")
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("Left"):
		if in_form_mode:
			get_viewport().set_input_as_handled()
			return
		_show_page(_page_index - 1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("Right"):
		if in_form_mode:
			get_viewport().set_input_as_handled()
			return
		_show_page(_page_index + 1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("Up"):
		if in_form_mode:
			forms_page.call("change_form", -1)
		else:
			_change_entry(-1)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("Down"):
		if in_form_mode:
			forms_page.call("change_form", 1)
		else:
			_change_entry(1)
		get_viewport().set_input_as_handled()
		return

	get_viewport().set_input_as_handled()


func _get_forms_page() -> Node2D:
	if _pages.size() > 2:
		return _pages[2]
	for p: Node2D in _pages:
		if p is PokedexPageForms or p.name.begins_with("Page_2"):
			return p
	return null


func _change_entry(dir: int) -> void:
	if _entries.is_empty() or _pokedex == null:
		return
	var next: int = _entry_index
	for _i: int in range(_entries.size()):
		next = wrapi(next + dir, 0, _entries.size())
		var sid: int = int(_entries[next]["id"])
		if _pokedex.is_seen(sid):
			_entry_index = next
			_load_species(sid)
			_play_cry()
			return


func _play_cry() -> void:
	if cry_player == null or _species == null:
		return
	var sid: int = int(_species.species_id)
	var form_i: int = get_selected_form_index(sid)
	var forms_page: Node2D = _get_forms_page()
	if form_i > 0 and forms_page is PokedexPageForms:
		var data: Dictionary = (forms_page as PokedexPageForms).get_current_form_data()
		var cry: AudioStream = data.get("cry") as AudioStream
		if cry:
			play_cry_stream(cry)
			return
	if _species.cry:
		play_cry_stream(_species.cry)


func _close() -> void:
	_active = false
	entry_closed.emit()
	queue_free()
