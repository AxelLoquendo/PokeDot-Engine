extends CanvasLayer
class_name PokedexListUI

signal list_closed

const VISIBLE_SLOTS: int = 8
const UNKNOWN_NAME: String = "-----"
const REGIONAL_MAX: int = 151

# Scroll del slider (coordenadas que pediste)
const SCROLL_X: float = 458.0
const SCROLL_Y_MIN: float = 95.0
const SCROLL_Y_MAX: float = 274.0

# Hold-to-scroll
const REPEAT_DELAY: float = 0.35   # espera antes de repetir
const REPEAT_RATE: float = 0.07    # velocidad al mantener

@onready var label_species_name: Label = $Species_Name
@onready var label_dex_type: Label = $Dex_Type
@onready var sprite_front: Sprite2D = $Front
@onready var label_seen: Label = $Seen
@onready var label_caught: Label = $Caught
@onready var scroll_bar: Sprite2D = $Scroll
@onready var arrow_up: Sprite2D = $Arrow_Up
@onready var arrow_down: Sprite2D = $Arrow_Down
@onready var slots_root: Control = $Control

@export var icon_seen: Texture2D  # graphics/ui_pokedex/icon_seen.png
@export var icon_own: Texture2D   # graphics/ui_pokedex/icon_own.png

var _pokedex: PokedexData = null
var _is_national: bool = true
var _entries: Array[Dictionary] = []
var _cursor: int = 0
var _scroll: int = 0
var _slot_nodes: Array[Control] = []
var _active: bool = false

var _hold_dir: int = 0
var _hold_timer: float = 0.0
var _repeating: bool = false

var _entry_ui: Node = null
var _player_data: CharacterPlayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_collect_slots()
	if icon_seen == null:
		icon_seen = load("res://graphics/ui_pokedex/icon_seen.png") as Texture2D
	if icon_own == null:
		icon_own = load("res://graphics/ui_pokedex/icon_own.png") as Texture2D


func _collect_slots() -> void:
	_slot_nodes.clear()
	for n: String in ["Slot", "Slot2", "Slot3", "Slot4", "Slot5", "Slot6", "Slot7", "Slot8"]:
		var slot: Control = slots_root.get_node_or_null(n) as Control
		if slot:
			_slot_nodes.append(slot)


func setup(player_data: CharacterPlayer, pokedex: PokedexData, is_national: bool = true) -> void:
	_player_data = player_data
	_pokedex = pokedex if pokedex else PokedexData.new()
	_is_national = is_national
	_build_entries()
	_cursor = 0
	_scroll = 0
	_hold_dir = 0
	_active = true
	if scroll_bar:
		scroll_bar.position = Vector2(SCROLL_X, SCROLL_Y_MIN)
	_refresh_ui()

func _try_open_entry() -> void:
	if _entries.is_empty() or _entry_ui != null:
		return
	var entry: Dictionary = _entries[_cursor]
	var sid: int = int(entry["id"])
	if not _pokedex.is_seen(sid):
		return

	_active = false
	var packed: PackedScene = load("res://scenes/ui_pokedex/pokedex_data.tscn") as PackedScene
	# o pokedex_entry.tscn si la renombras
	if packed == null:
		_active = true
		return

	_entry_ui = packed.instantiate()
	get_parent().add_child(_entry_ui)
	if _entry_ui.has_method("setup"):
		_entry_ui.call("setup", sid, _pokedex, _entries, _cursor)
	if _entry_ui.has_signal("entry_closed"):
		_entry_ui.connect("entry_closed", _on_entry_closed)
	visible = false


func _on_entry_closed() -> void:
	_entry_ui = null
	visible = true
	_active = true
	_refresh_ui()

func _build_entries() -> void:
	_entries.clear()
	# Solo índice en memoria: no carga .tres
	for e: Dictionary in SpeciesDatabase.get_dex_index():
		var nat: int = int(e["national"])
		if not _is_national and (nat < 1 or nat > REGIONAL_MAX):
			continue
		_entries.append({
			"id": int(e["id"]),
			"dex": nat,
			"name": str(e["name"]),
		})


func _process(delta: float) -> void:
	if not _active:
		return

	var dir: int = 0
	if Input.is_action_pressed("Down"):
		dir = 1
	elif Input.is_action_pressed("Up"):
		dir = -1

	if dir == 0:
		_hold_dir = 0
		_hold_timer = 0.0
		_repeating = false
		return

	if dir != _hold_dir:
		# Primera pulsación ya la maneja _input; aquí solo hold
		_hold_dir = dir
		_hold_timer = 0.0
		_repeating = false
		return

	_hold_timer += delta
	if not _repeating:
		if _hold_timer >= REPEAT_DELAY:
			_repeating = true
			_hold_timer = 0.0
			_move(dir)
	else:
		if _hold_timer >= REPEAT_RATE:
			_hold_timer = 0.0
			_move(dir)


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_echo():
		return

	# Consumir input para que no llegue al overworld
	if event.is_action_pressed("Up"):
		_move(-1)
		_hold_dir = -1
		_hold_timer = 0.0
		_repeating = false
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("Down"):
		_move(1)
		_hold_dir = 1
		_hold_timer = 0.0
		_repeating = false
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonB"):
		_close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("buttonA"):
		_try_open_entry()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		# Bloquea movimiento del jugador mientras la lista está abierta
		get_viewport().set_input_as_handled()


func _move(dir: int) -> void:
	if _entries.is_empty():
		return
	_cursor = clampi(_cursor + dir, 0, _entries.size() - 1)
	if _cursor < _scroll:
		_scroll = _cursor
	elif _cursor >= _scroll + VISIBLE_SLOTS:
		_scroll = _cursor - VISIBLE_SLOTS + 1
	_refresh_ui()


func _refresh_ui() -> void:
	_refresh_slots()
	_refresh_preview()
	_refresh_counters()
	_refresh_scroll_visual()


func _refresh_slots() -> void:
	for i: int in range(_slot_nodes.size()):
		var slot: Control = _slot_nodes[i]
		var entry_index: int = _scroll + i
		var lbl_num: Label = slot.get_node_or_null("Dex_number") as Label
		var lbl_name: Label = slot.get_node_or_null("Name_Specie") as Label
		var status: Sprite2D = slot.get_node_or_null("Status") as Sprite2D

		if entry_index >= _entries.size():
			if lbl_num: lbl_num.text = ""
			if lbl_name: lbl_name.text = ""
			if status:
				status.texture = null
				status.visible = false
			slot.modulate = Color(1, 1, 1, 0.35)
			continue

		var entry: Dictionary = _entries[entry_index]
		var sid: int = int(entry["id"])
		var seen: bool = _pokedex.is_seen(sid)
		var owned: bool = _pokedex.is_owned(sid)

		if lbl_num:
			lbl_num.text = "%03d" % int(entry["dex"])
		if lbl_name:
			lbl_name.text = str(entry["name"]) if seen else UNKNOWN_NAME

		# Status: owned > seen > ninguno
		if status:
			if owned and icon_own:
				status.texture = icon_own
				status.visible = true
			elif seen and icon_seen:
				status.texture = icon_seen
				status.visible = true
			else:
				status.texture = null
				status.visible = false

		slot.modulate = Color(1.25, 1.25, 1.25, 1.0) if entry_index == _cursor else Color.WHITE


func _refresh_preview() -> void:
	if _entries.is_empty() or _cursor < 0 or _cursor >= _entries.size():
		label_species_name.text = ""
		sprite_front.texture = null
		return

	var entry: Dictionary = _entries[_cursor]
	var sid: int = int(entry["id"])
	if not _pokedex.is_seen(sid):
		label_species_name.text = UNKNOWN_NAME
		sprite_front.texture = null
		return

	# Aquí SÍ cargamos el .tres (solo el seleccionado y visto)
	var data: PokemonDataStruct = SpeciesDatabase.get_species(sid as Species.SpeciesID)
	if data:
		label_species_name.text = data.species_name
		sprite_front.texture = data.front_sprite
	else:
		label_species_name.text = str(entry["name"])
		sprite_front.texture = null


func _refresh_counters() -> void:
	var seen_c: int = 0
	var owned_c: int = 0
	for e: Dictionary in _entries:
		var sid: int = int(e["id"])
		if _pokedex.is_seen(sid):
			seen_c += 1
		if _pokedex.is_owned(sid):
			owned_c += 1
	if label_seen:
		label_seen.text = "Vistos: %04d" % seen_c
	if label_caught:
		label_caught.text = "Obtenidos: %04d" % owned_c
	if label_dex_type:
		label_dex_type.text = "Pokédex Nacional" if _is_national else "Pokédex Regional"


func _refresh_scroll_visual() -> void:
	var max_scroll: int = maxi(_entries.size() - VISIBLE_SLOTS, 0)
	if arrow_up:
		arrow_up.visible = _scroll > 0
	if arrow_down:
		arrow_down.visible = _scroll < max_scroll
	if scroll_bar == null:
		return
	scroll_bar.position.x = SCROLL_X
	if max_scroll <= 0:
		scroll_bar.position.y = SCROLL_Y_MIN
	else:
		var t: float = float(_scroll) / float(max_scroll)
		scroll_bar.position.y = lerpf(SCROLL_Y_MIN, SCROLL_Y_MAX, t)

func _close() -> void:
	_active = false
	list_closed.emit()
	queue_free()
