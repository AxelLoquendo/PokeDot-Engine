extends RefCounted
class_name CaptureFlow

## Flujo post-captura estilo juegos oficiales:
## (mensaje dex en el battle manager) → ¿mote? → entrada de dex si es nuevo.

const DEX_ENTRY_SCENE: PackedScene = preload("res://scenes/ui_pokedex/pokedex_data.tscn")
const NAME_MAX_LEN: int = 12


static func register_seen(player_data: CharacterPlayer, mon: PokemonInstance) -> bool:
	if player_data == null or mon == null:
		return false
	var dex: PokedexData = player_data.ensure_pokedex()
	var sid: int = int(mon.species_id)
	if sid <= 0:
		return false
	var first: bool = not dex.is_seen(sid)
	dex.set_seen(sid)
	return first


static func register_owned(player_data: CharacterPlayer, mon: PokemonInstance) -> bool:
	if player_data == null or mon == null:
		return false
	var dex: PokedexData = player_data.ensure_pokedex()
	var sid: int = int(mon.species_id)
	if sid <= 0:
		return false
	var first: bool = not dex.is_owned(sid)
	dex.set_owned(sid)
	return first


static func register_encounter_seen(player_data: CharacterPlayer, battle: BattleManager) -> void:
	if player_data == null or battle == null:
		return
	for b: BattleBattler in battle.enemy_actives:
		if b != null and b.pokemon != null:
			register_seen(player_data, b.pokemon)
	for mon: PokemonInstance in battle.enemy_party:
		if mon != null:
			register_seen(player_data, mon)


## Nombre de especie (sin mote previo).
static func _species_display_name(mon: PokemonInstance) -> String:
	if mon == null:
		return "Pokémon"
	var species: PokemonDataStruct = mon.get_species()
	if species != null and not species.species_name.is_empty():
		return species.species_name
	return mon.get_display_name()


## ¿Ponerle un mote? → LineEdit + botón Aceptar (PC, Android y teclado virtual).
static func prompt_nickname(tree: SceneTree, mon: PokemonInstance) -> void:
	if tree == null or mon == null:
		return

	var species_name: String = _species_display_name(mon)

	var choice: int = await DialogueManager.choose(
		["Sí", "No"],
		Vector2(468, 280)
	)
	if choice != 0:
		mon.nickname = ""
		return

	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 210
	layer.name = "NicknameOverlay"
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(layer)

	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 180)
	layer.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "¿Mote para %s?" % species_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var edit: LineEdit = LineEdit.new()
	edit.max_length = NAME_MAX_LEN
	edit.placeholder_text = species_name
	edit.custom_minimum_size = Vector2(380, 40)
	edit.clear_button_enabled = true
	edit.virtual_keyboard_enabled = true
	edit.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_DEFAULT
	vbox.add_child(edit)

	var hint: Label = Label.new()
	hint.text = "Vacío = nombre de la especie"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	var btn_row: HBoxContainer = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var btn_ok: Button = Button.new()
	btn_ok.text = "Aceptar"
	btn_ok.custom_minimum_size = Vector2(140, 44)
	btn_row.add_child(btn_ok)

	await tree.process_frame
	var vp: Vector2 = tree.root.get_viewport().get_visible_rect().size
	panel.position = Vector2(
		(vp.x - panel.size.x) * 0.5,
		(vp.y - panel.size.y) * 0.32
	)
	edit.grab_focus()

	var finished: bool = false
	var submitted_text: String = ""

	edit.text_submitted.connect(func(text: String) -> void:
		if not finished:
			finished = true
			submitted_text = text
	)
	btn_ok.pressed.connect(func() -> void:
		if not finished:
			finished = true
			submitted_text = edit.text
	)

	while not finished:
		await tree.process_frame
		if edit.has_focus() and (
				Input.is_action_just_pressed("ui_accept")
				or Input.is_action_just_pressed("buttonA")
		):
			finished = true
			submitted_text = edit.text

	var nick: String = submitted_text.strip_edges()
	mon.nickname = "" if nick.is_empty() else nick

	if is_instance_valid(layer):
		layer.queue_free()
	await tree.process_frame


static func show_dex_entry(tree: SceneTree, species_id: int, pokedex: PokedexData) -> void:
	if tree == null or species_id <= 0 or pokedex == null:
		return
	if DEX_ENTRY_SCENE == null:
		return
	var entry: PokedexEntryUI = DEX_ENTRY_SCENE.instantiate() as PokedexEntryUI
	if entry == null:
		return
	entry.layer = 205
	tree.root.add_child(entry)
	entry.setup(species_id, pokedex)
	await entry.entry_closed
	if is_instance_valid(entry):
		entry.queue_free()
	await tree.process_frame


## Tras captura: apodo siempre; entrada de dex solo si first_owned.
## El mensaje de “datos registrados” lo emite el BattleManager *antes* de llamar esto.
static func run_after_capture(
	tree: SceneTree,
	player_data: CharacterPlayer,
	caught: PokemonInstance,
	first_owned: bool
) -> void:
	if tree == null or player_data == null or caught == null:
		return
	await prompt_nickname(tree, caught)
	if first_owned:
		await show_dex_entry(tree, int(caught.species_id), player_data.ensure_pokedex())
