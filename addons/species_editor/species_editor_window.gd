@tool
extends Window

## Unified PokeDot Engine workspace. Existing docks retain their repositories,
## forms, validation and persistence; this shell only owns navigation and theme.
class_name PokeDotEngineWorkspace

const SPECIES_DOCK_SCRIPT: Script = preload("res://addons/species_editor/species_dock.gd")
const ABILITY_DOCK_SCRIPT: Script = preload("res://addons/ability_editor/ability_dock.gd")
const MOVE_DOCK_SCRIPT: Script = preload("res://addons/move_editor/move_dock.gd")
const ITEM_DOCK_SCRIPT: Script = preload("res://addons/item_editor/item_dock.gd")
const WINDOW_SIZE: Vector2i = Vector2i(1420, 860)
const WINDOW_MIN_SIZE: Vector2i = Vector2i(980, 620)
const BACKGROUND: Color = Color("12161d")
const SURFACE: Color = Color("1a2029")
const SURFACE_RAISED: Color = Color("222b36")
const SURFACE_INPUT: Color = Color("111820")
const BORDER: Color = Color("303c4b")
const BORDER_FOCUS: Color = Color("5e91bd")
const TEXT: Color = Color("e7edf4")
const MUTED: Color = Color("96a5b6")
const ACCENT: Color = Color("62a5e8")

var content_host: Control
var status_label: Label
var section_subtitle: Label
var module_buttons: Dictionary = {}
var modules: Dictionary = {}
var loading_token: int = 0
var active_module: String = "species"

func _init() -> void:
	title = "PokeDot Engine"
	size = WINDOW_SIZE
	min_size = WINDOW_MIN_SIZE

func _ready() -> void:
	close_requested.connect(_on_close_requested)
	_build_theme()
	_build_shell()
	_select_module("species")

func _on_close_requested() -> void:
	# Hide instead of freeing so the plugin can reopen the same workspace and
	# preserve the module state while the editor session remains active.
	hide()

func _build_theme() -> void:
	var editor_theme: Theme = Theme.new()
	editor_theme.default_font_size = 13
	for control_type: String in ["Label", "Button", "LineEdit", "SpinBox", "OptionButton", "CheckBox", "TextEdit", "ItemList", "Tree", "TabBar", "TabContainer", "Window"]:
		for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_selected_color"]:
			editor_theme.set_color(color_name, control_type, TEXT)
		editor_theme.set_color("font_disabled_color", control_type, MUTED)
		editor_theme.set_color("font_placeholder_color", control_type, MUTED)
	editor_theme.set_color("caret_color", "LineEdit", ACCENT)
	editor_theme.set_stylebox("normal", "Button", _style(SURFACE_RAISED, BORDER, 6, 1))
	editor_theme.set_stylebox("hover", "Button", _style(Color("2b3b4e"), BORDER_FOCUS, 6, 1))
	editor_theme.set_stylebox("pressed", "Button", _style(Color("162231"), ACCENT, 6, 1))
	editor_theme.set_stylebox("focus", "Button", _style(SURFACE_RAISED, BORDER_FOCUS, 6, 1))
	for control_type: String in ["LineEdit", "SpinBox", "TextEdit"]:
		editor_theme.set_stylebox("normal", control_type, _style(SURFACE_INPUT, BORDER, 5, 1))
		editor_theme.set_stylebox("focus", control_type, _style(SURFACE_INPUT, BORDER_FOCUS, 5, 1))
	theme = editor_theme

func _style(fill: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 6.0
	box.content_margin_bottom = 6.0
	return box

func _build_shell() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var header: PanelContainer = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 76)
	header.add_theme_stylebox_override("panel", _style(SURFACE, BORDER, 8, 1))
	root.add_child(header)
	var header_margin: MarginContainer = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 18)
	header_margin.add_theme_constant_override("margin_top", 10)
	header_margin.add_theme_constant_override("margin_bottom", 10)
	header.add_child(header_margin)
	var header_rows: VBoxContainer = VBoxContainer.new()
	header_rows.add_theme_constant_override("separation", 3)
	header_margin.add_child(header_rows)
	var heading: Label = Label.new()
	heading.text = "PokeDot Engine"
	heading.add_theme_font_size_override("font_size", 20)
	header_rows.add_child(heading)
	section_subtitle = Label.new()
	section_subtitle.text = "Unified data workspace"
	section_subtitle.add_theme_color_override("font_color", MUTED)
	header_rows.add_child(section_subtitle)
	var close_button: Button = Button.new()
	close_button.text = "Close workspace"
	close_button.tooltip_text = "Hide the workspace window"
	close_button.custom_minimum_size = Vector2(170, 34)
	close_button.pressed.connect(_on_close_requested)
	header_rows.add_child(close_button)
	var body: HBoxContainer = HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)
	var sidebar: PanelContainer = PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(218, 0)
	sidebar.add_theme_stylebox_override("panel", _style(SURFACE, BORDER, 8, 1))
	body.add_child(sidebar)
	var side_margin: MarginContainer = MarginContainer.new()
	for pair: Array in [["margin_left", 14], ["margin_right", 14], ["margin_top", 16], ["margin_bottom", 16]]:
		side_margin.add_theme_constant_override(str(pair[0]), int(pair[1]))
	sidebar.add_child(side_margin)
	var nav: VBoxContainer = VBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	side_margin.add_child(nav)
	var nav_title: Label = Label.new()
	nav_title.text = "Workspace"
	nav_title.add_theme_color_override("font_color", ACCENT)
	nav.add_child(nav_title)
	var nav_hint: Label = Label.new()
	nav_hint.text = "Selecciona un módulo para trabajar con sus datos."
	nav_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nav_hint.add_theme_color_override("font_color", MUTED)
	nav.add_child(nav_hint)
	var definitions: Array[Dictionary] = [{"id":"species", "label":"Species", "hint":"Especies, formas y gráficos"}, {"id":"abilities", "label":"Abilities", "hint":"Habilidades"}, {"id":"moves", "label":"Moves", "hint":"Movimientos"}, {"id":"items", "label":"Items", "hint":"Objetos"}]
	for definition: Dictionary in definitions:
		var button: Button = Button.new()
		button.text = str(definition["label"])
		button.tooltip_text = str(definition["hint"])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 38)
		button.pressed.connect(_on_module_pressed.bind(str(definition["id"])))
		nav.add_child(button)
		module_buttons[str(definition["id"])] = button
	nav.add_spacer(false)
	status_label = Label.new()
	status_label.add_theme_color_override("font_color", MUTED)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nav.add_child(status_label)
	var content_panel: PanelContainer = PanelContainer.new()
	content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_panel.add_theme_stylebox_override("panel", _style(SURFACE, BORDER, 8, 1))
	body.add_child(content_panel)
	var content_margin: MarginContainer = MarginContainer.new()
	for pair: Array in [["margin_left", 10], ["margin_top", 10], ["margin_right", 10], ["margin_bottom", 10]]:
		content_margin.add_theme_constant_override(str(pair[0]), int(pair[1]))
	content_panel.add_child(content_margin)
	content_host = Control.new()
	content_host.name = "ModuleContent"
	content_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.add_child(content_host)

func _on_module_pressed(module_id: String) -> void:
	_select_module(module_id)

func _select_module(module_id: String) -> void:
	if not module_buttons.has(module_id):
		return
	active_module = module_id
	for id: String in module_buttons:
		var button: Button = module_buttons[id] as Button
		button.button_pressed = id == module_id
		button.modulate = ACCENT if id == module_id else Color.WHITE
	for id: String in modules:
		var module_control: Control = modules[id] as Control
		module_control.visible = id == module_id
	status_label.text = "Cargando %s..." % _module_label(module_id)
	if not modules.has(module_id):
		loading_token += 1
		var token: int = loading_token
		call_deferred("_instantiate_module", module_id, token)
	else:
		status_label.text = "%s activo" % _module_label(module_id)

func _instantiate_module(module_id: String, token: int) -> void:
	if token != loading_token or active_module != module_id or modules.has(module_id):
		return
	var script: Script = _script_for_module(module_id)
	if script == null:
		status_label.text = "No se pudo cargar %s" % _module_label(module_id)
		return
	var module_control: Control = script.new() as Control
	if module_control == null:
		status_label.text = "%s no devolvió un Control" % _module_label(module_id)
		return
	module_control.name = "%sModule" % module_id.capitalize()
	module_control.theme = theme
	module_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_host.add_child(module_control)
	modules[module_id] = module_control
	_strip_ui_symbols(module_control)
	status_label.text = "%s activo" % _module_label(module_id)

func _script_for_module(module_id: String) -> Script:
	match module_id:
		"species": return SPECIES_DOCK_SCRIPT
		"abilities": return ABILITY_DOCK_SCRIPT
		"moves": return MOVE_DOCK_SCRIPT
		"items": return ITEM_DOCK_SCRIPT
	return null

func _module_label(module_id: String) -> String:
	match module_id:
		"abilities": return "Abilities"
		"moves": return "Moves"
		"items": return "Items"
		_: return "Species"

func _strip_ui_symbols(root: Node) -> void:
	if root is Label:
		(root as Label).text = _without_symbols((root as Label).text)
	elif root is Button:
		(root as Button).text = _without_symbols((root as Button).text)
	for child: Node in root.get_children():
		_strip_ui_symbols(child)

func _without_symbols(value: String) -> String:
	var result: String = value
	for token: String in ["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""]:
		result = result.replace(token, "")
	return result.strip_edges()
