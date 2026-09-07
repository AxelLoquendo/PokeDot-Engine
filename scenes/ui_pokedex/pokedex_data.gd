extends CanvasLayer
class_name PokedexEntryUI

signal entry_closed

const PAGE_COUNT: int = 4

@onready var pages_root: Node2D = $Pages
@onready var cry_player: AudioStreamPlayer = $Cry

var _pages: Array[Node2D] = []
var _page_index: int = 0
var _species: PokemonDataStruct = null
var _owned: bool = false
var _active: bool = false

# Lista de especies vistas (para ← → entre entradas)
var _entries: Array[Dictionary] = []
var _entry_index: int = 0
var _pokedex: PokedexData = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pages.clear()
	if pages_root:
		for c: Node in pages_root.get_children():
			if c is Node2D:
				_pages.append(c as Node2D)
	_show_page(0)


func setup(
	species_id: int,
	pokedex: PokedexData,
	entries: Array[Dictionary] = [],
	entry_index: int = 0
) -> void:
	_pokedex = pokedex
	_entries = entries
	_entry_index = entry_index
	_load_species(species_id)
	_active = true
	_page_index = 0
	_show_page(0)
	_play_cry()


func _load_species(species_id: int) -> void:
	_species = SpeciesDatabase.get_species(species_id as Species.SpeciesID)
	_owned = _pokedex != null and _pokedex.is_owned(species_id)
	_refresh_pages()


func _refresh_pages() -> void:
	if _species == null:
		return
	for p: Node2D in _pages:
		if p.has_method("setup"):
			p.call("setup", _species, _owned)


func _show_page(index: int) -> void:
	_page_index = clampi(index, 0, maxi(_pages.size() - 1, 0))
	for i: int in range(_pages.size()):
		_pages[i].visible = (i == _page_index)


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_echo():
		return

	if event.is_action_pressed("buttonB"):
		_close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Left") or event.is_action_pressed("ui_left"):
		# En page forms, Left/Right podrían ser otra cosa; por ahora: cambiar página
		_show_page(_page_index - 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Right") or event.is_action_pressed("ui_right"):
		_show_page(_page_index + 1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Up"):
		_change_entry(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Down"):
		_change_entry(1)
		get_viewport().set_input_as_handled()
	else:
		get_viewport().set_input_as_handled()


func _change_entry(dir: int) -> void:
	if _entries.is_empty() or _pokedex == null:
		return
	var next: int = _entry_index
	# Solo saltar a especies vistas
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
	if _species.cry == null:
		return
	cry_player.stop()
	cry_player.stream = _species.cry
	cry_player.play()


func _close() -> void:
	_active = false
	entry_closed.emit()
	queue_free()
