@tool
extends Control
class_name WildEncounterEditor

## Workspace editor for high-grass encounters. It deliberately does not paint
## tiles: runtime TileBehaviour Grass remains the authority for encounter cells.
const ACCENT: Color = Color("62a5e8")
const MUTED: Color = Color("96a5b6")
var maps: Array[Dictionary] = []
var map_list: ItemList
var map_path_label: Label
var attributes_text: Label
var table_state: Label
var rows_box: VBoxContainer
var encounter_grid: GridContainer
var add_row_button: Button
var selected_map: Dictionary = {}
var selected_table: Object = null
var selected_scene_instance: Node = null
var species_names: Array[String] = []
var species_values: Array[int] = []
var species_data_by_id: Dictionary = {} # int -> PokemonDataStruct/Resource
var species_display_by_id: Dictionary = {} # int -> String
var species_icon_by_id: Dictionary = {} # int -> Texture2D
var species_base_id_by_id: Dictionary = {} # int -> int, useful for form diagnostics

func _init() -> void:
	custom_minimum_size = Vector2(900, 560)

func _ready() -> void:
	_build_ui()
	_scan_species_catalog()
	_scan_maps()

func _build_ui() -> void:
	var split: HSplitContainer = HSplitContainer.new()
	split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(split)
	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size = Vector2(280, 0)
	split.add_child(left)
	var title: Label = Label.new()
	title.text = "Wild Encounters"
	title.add_theme_font_size_override("font_size", 18)
	left.add_child(title)
	var hint: Label = Label.new()
	hint.text = "Map catalog · high-grass tables"
	hint.add_theme_color_override("font_color", MUTED)
	left.add_child(hint)
	var refresh: Button = Button.new()
	refresh.text = "Reload map catalog"
	refresh.pressed.connect(_scan_maps)
	left.add_child(refresh)
	map_list = ItemList.new()
	map_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_list.item_selected.connect(_select_map)
	left.add_child(map_list)
	var right: VBoxContainer = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	var heading: Label = Label.new()
	heading.text = "Wild encounters"
	heading.add_theme_font_size_override("font_size", 18)
	right.add_child(heading)
	map_path_label = Label.new()
	map_path_label.add_theme_color_override("font_color", MUTED)
	right.add_child(map_path_label)
	attributes_text = Label.new()
	attributes_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(attributes_text)
	var actions: HBoxContainer = HBoxContainer.new()
	right.add_child(actions)
	var create: Button = Button.new()
	create.text = "Create table"
	create.pressed.connect(_create_table)
	actions.add_child(create)
	var remove: Button = Button.new()
	remove.text = "Remove table"
	remove.pressed.connect(_remove_table)
	actions.add_child(remove)
	add_row_button = Button.new()
	add_row_button.text = "Add species"
	add_row_button.pressed.connect(_add_row)
	actions.add_child(add_row_button)
	table_state = Label.new()
	table_state.add_theme_color_override("font_color", ACCENT)
	right.add_child(table_state)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	rows_box = VBoxContainer.new()
	rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows_box)
	split.split_offset = 280

func _scan_species_catalog() -> void:
	# Build one catalog from both the declared enum and the actual PokemonDataStruct
	# resources. Legacy encounter rows store only a typed numeric SpeciesID, so the
	# resource scan is what supplies names and icons (including forms).
	species_names.clear()
	species_values.clear()
	species_data_by_id.clear()
	species_display_by_id.clear()
	species_icon_by_id.clear()
	species_base_id_by_id.clear()
	var enum_paths: Array[String] = [
		"res://data_core/pokemon/species.gd",
		"res://data_core/pokemon/species_id.gd",
		"res://data_core/species/species.gd"
	]
	for path: String in enum_paths:
		if FileAccess.file_exists(path):
			_parse_species_enum(FileAccess.get_file_as_string(path))
		if not species_values.is_empty():
			break
	_scan_species_resources("res://data_core/pokemon/resources/")
	# Form resources may live outside the canonical resources directory in projects
	# that keep the form system beside its editor. Scan both locations; registration
	# is keyed by the form's own SpeciesID, never by form_id.
	_scan_species_resources("res://data_core/pokemon/forms/")
	_scan_species_resources("res://data_core/forms/")
	# Some projects expose a SpeciesDB autoload; use it when available without
	# making the editor depend on a particular autoload name or startup order.
	var db: Object = get_node_or_null("/root/SpeciesDB") as Object
	if is_instance_valid(db) and db.has_method("get_all_species"):
		var loaded: Variant = db.call("get_all_species")
		if loaded is Array:
			for value: Variant in loaded as Array:
				_register_species_resource(value as Object)
	# Resources may be the only catalog source in projects without an enum file.
	var ids: Array[int] = []
	for key: Variant in species_data_by_id.keys():
		ids.append(int(key))
	for value: int in species_values:
		if not ids.has(value):
			ids.append(value)
	ids.sort()
	species_names.clear()
	species_values.clear()
	for id: int in ids:
		species_values.append(id)
		species_names.append(str(species_display_by_id.get(id, "Species ID %d" % id)))

func _parse_species_enum(source: String) -> void:
	var enum_open: bool = false
	var next_value: int = 0
	for raw_line: String in source.split("\n"):
		var line: String = raw_line.strip_edges()
		if line.begins_with("enum "):
			enum_open = line.contains("SpeciesID") or line.contains("SpeciesId")
			# A one-line enum is uncommon but valid; continue parsing its body.
			line = line.substr(line.find("{") + 1) if line.contains("{") else ""
		if not enum_open and not line.begins_with("const SPECIES_"):
			continue
		if enum_open and line.contains("}"):
			line = line.replace("}", "")
			enum_open = false
		line = line.trim_suffix(",").strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts: PackedStringArray = line.split("=")
		var name: String = parts[0].strip_edges()
		if name.begins_with("const "):
			name = name.trim_prefix("const ").strip_edges()
		# Remove an optional type annotation from const declarations.
		if name.contains(":"):
			name = name.split(":")[0].strip_edges()
		if not name.begins_with("SPECIES_"):
			continue
		var id: int = next_value
		if parts.size() > 1:
			var value_text: String = parts[1].strip_edges().trim_suffix(",")
			if value_text.is_valid_int():
				id = int(value_text)
		next_value = id + 1
		_register_species_id(id, name)

func _register_species_id(id: int, enum_name: String) -> void:
	if not species_values.has(id):
		species_values.append(id)
		species_names.append(enum_name)
	species_display_by_id[id] = enum_name

func _scan_species_resources(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		var full: String = path.path_join(entry)
		if dir.current_is_dir() and not entry.begins_with("."):
			_scan_species_resources(full)
		elif entry.ends_with(".tres") or entry.ends_with(".res"):
			_register_species_resource(ResourceLoader.load(full))
		entry = dir.get_next()
	dir.list_dir_end()

func _register_species_resource(value: Object) -> void:
	if not is_instance_valid(value) or not _has_property(value, "species_id"):
		return
	var raw_id: Variant = value.get("species_id")
	if not (raw_id is int or raw_id is float):
		return
	var id: int = int(raw_id)
	if id == 0:
		return
	species_data_by_id[id] = value
	var name: String = _display_name_for_resource(value, id)
	species_display_by_id[id] = name
	var base_id: Variant = _read_property(value, "base_species_id", 0)
	if base_id is int or base_id is float:
		species_base_id_by_id[id] = int(base_id)
	var icon_value: Variant = _read_property(value, "icon_sprite", null)
	var icon: Texture2D = _first_frame_texture(icon_value)
	if icon != null:
		species_icon_by_id[id] = icon
	# PokemonDataStruct may embed PokemonFormData entries instead of saving each
	# form as a separate .tres. Register those IDs too, preserving their identity.
	if _has_property(value, "forms"):
		var forms_value: Variant = value.get("forms")
		if forms_value is Array:
			for form_value: Variant in forms_value as Array:
				_register_species_resource(form_value as Object)

func _display_name_for_resource(value: Object, id: int) -> String:
	var name_value: Variant = _read_property(value, "display_name", "")
	if not (name_value is String) or str(name_value).strip_edges().is_empty():
		name_value = _read_property(value, "species_name", "")
	var name: String = str(name_value).strip_edges()
	return name if not name.is_empty() else "Species ID %d" % id

func _first_frame_texture(value: Variant) -> Texture2D:
	# SpriteFrames and AnimatedTexture are resources, not Texture2D. Always take
	# frame zero so an editor row cannot animate or show a horizontal strip.
	if value is SpriteFrames:
		var frames: SpriteFrames = value as SpriteFrames
		var animations: PackedStringArray = frames.get_animation_names()
		if not animations.is_empty() and frames.get_frame_count(animations[0]) > 0:
			return _first_frame_texture(frames.get_frame_texture(animations[0], 0))
		return null
	if value is AnimatedTexture:
		var animated: AnimatedTexture = value as AnimatedTexture
		if animated.frames > 0:
			return _first_frame_texture(animated.get_frame_texture(0))
		return null
	if value is Texture2D:
		var texture: Texture2D = value as Texture2D
		# Catalog icons are 128x64 sheets: only the left 64x64 frame is
		# displayed. AtlasTexture keeps the source asset untouched, including forms.
		if texture.get_width() >= 128 and texture.get_height() >= 64:
			var crop: AtlasTexture = AtlasTexture.new()
			crop.atlas = texture
			crop.region = Rect2(0, 0, 64, 64)
			return crop
		return texture
	return null

func _scan_maps() -> void:
	# Map instances from the previous scan may already have been freed by Godot.
	# Drop every reference before loading the catalog again.
	_clear_selection()
	_free_scanned_instances()
	maps.clear()
	if map_list == null:
		return
	map_list.clear()
	_scan_dir("res://", maps)
	for record: Dictionary in maps:
		map_list.add_item("%s  [%s]" % [str(record["name"]), str(record["id"])])
	if maps.is_empty():
		map_list.add_item("No map scenes found")

func _free_scanned_instances() -> void:
	for record: Dictionary in maps:
		var instance: Node = record.get("scene_instance") as Node
		if is_instance_valid(instance):
			instance.queue_free()
	selected_scene_instance = null

func _scan_dir(path: String, result: Array[Dictionary]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var full: String = path.path_join(entry)
		if dir.current_is_dir():
			_scan_dir(full, result)
		elif entry.ends_with(".tscn"):
			var packed: PackedScene = ResourceLoader.load(full, "PackedScene", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
			if packed != null:
				var instance: Node = packed.instantiate()
				var attrs: Object = _find_map_attributes(instance)
				if is_instance_valid(attrs) and (_has_property(attrs, "map_id_section") or _has_property(attrs, "grass_encounters")):
					var id: String = str(_read_property(attrs, "map_id_section", ""))
					var name: String = str(_read_property(attrs, "map_name", entry.get_basename()))
					# Keep the instance alive: its MapAttributes and any embedded
					# WildEncounterTable resources belong to this loaded scene.
					result.append({"path": full, "id": id, "name": name, "attributes": attrs, "packed": packed, "scene_instance": instance})
				else:
					if is_instance_valid(instance):
						instance.queue_free()
		entry = dir.get_next()
	dir.list_dir_end()

func _find_map_attributes(root: Node) -> Object:
	if not is_instance_valid(root):
		return null
	if _has_property(root, "map_id_section") or _has_property(root, "grass_encounters"):
		return root
	for child: Node in root.get_children():
		var found: Object = _find_map_attributes(child)
		if is_instance_valid(found):
			return found
	return null

func _select_map(index: int) -> void:
	if index < 0 or index >= maps.size():
		return
	var candidate: Dictionary = maps[index]
	var attrs: Object = candidate.get("attributes") as Object
	if not is_instance_valid(attrs):
		_clear_selection()
		return
	selected_map = candidate
	selected_scene_instance = candidate.get("scene_instance") as Node
	map_path_label.text = "%s\nStable map ID: %s" % [str(candidate["path"]), str(candidate["id"])]
	attributes_text.text = "MapAttributes: %s\nGrass table property: %s" % [str(_read_property(attrs, "map_name", "")), "present" if _has_property(attrs, "grass_encounters") else "not declared"]
	var table_value: Variant = _read_property(attrs, "grass_encounters", null)
	selected_table = table_value as Object if table_value is Object and is_instance_valid(table_value as Object) else null
	_render_table()

func _render_table() -> void:
	if rows_box == null:
		return
	if not is_instance_valid(selected_table):
		selected_table = null
	for child: Node in rows_box.get_children():
		child.queue_free()
	if selected_table == null:
		table_state.text = "No WildEncounterTable assigned to this map."
		return
	table_state.text = "WildEncounterTable assigned · Grass tiles only"
	# Header and controls use one shared seven-column grid. This keeps every
	# label directly above its field, including when the table is resized.
	var header: GridContainer = GridContainer.new()
	header.columns = 7
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var header_texts: Array[String] = ["Especie", "", "Nivel mínimo", "Nivel máximo", "Peso", "%", ""]
	var header_widths: Array[float] = [220.0, 44.0, 96.0, 96.0, 120.0, 64.0, 76.0]
	for column: int in range(header_texts.size()):
		var header_label: Label = Label.new()
		header_label.text = header_texts[column]
		header_label.custom_minimum_size = Vector2(header_widths[column], 34)
		header_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		header_label.add_theme_color_override("font_color", ACCENT)
		header.add_child(header_label)
	rows_box.add_child(header)
	var entries: Array = _entries(selected_table)
	var total_weight: float = 0.0
	for candidate: Variant in entries:
		var candidate_entry: Object = candidate as Object
		if is_instance_valid(candidate_entry):
			total_weight += maxf(0.0, float(_read_property(candidate_entry, "weight", _read_property(candidate_entry, "probability", 0))))
	var weight_note: Label = Label.new()
	weight_note.text = "El peso es relativo (no un porcentaje). %s" % ("Se muestra también la proporción sobre el total." if total_weight > 0.0 else "Añade pesos mayores que cero para calcular proporciones.")
	weight_note.add_theme_color_override("font_color", MUTED)
	rows_box.add_child(weight_note)
	encounter_grid = GridContainer.new()
	encounter_grid.columns = 7
	encounter_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_box.add_child(encounter_grid)
	for index: int in range(entries.size()):
		var entry: Object = entries[index] as Object
		if is_instance_valid(entry):
			_add_row_control(entry, index, total_weight)

func _add_row_control(entry: Object, index: int, total_weight: float) -> void:
	if encounter_grid == null:
		return
	var species: OptionButton = OptionButton.new()
	species.custom_minimum_size = Vector2(220, 36)
	species.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var species_field: String = "species_id" if _has_property(entry, "species_id") else "species"
	var current_species_id: int = int(_read_property(entry, species_field, 0))
	for i: int in range(species_names.size()):
		var catalog_id: int = species_values[i]
		var display_name: String = species_names[i]
		if catalog_id == current_species_id and species_display_by_id.has(catalog_id):
			display_name = str(species_display_by_id[catalog_id])
		species.add_item("%s · %s" % [display_name, catalog_id], catalog_id)
		if species_icon_by_id.has(catalog_id):
			species.set_item_icon(species.item_count - 1, species_icon_by_id[catalog_id] as Texture2D)
	if not species_values.has(current_species_id):
		species.add_item("Unknown species ID %d" % current_species_id, current_species_id)
		species.set_item_disabled(species.item_count - 1, true)
	var current_index: int = species.get_item_index(current_species_id)
	if current_index >= 0:
		species.select(current_index)
	species.item_selected.connect(func(selected: int) -> void: _write_property(entry, species_field, species.get_item_id(selected)))
	encounter_grid.add_child(species)
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = "Species icon (first 64×64 region)"
	icon.texture = _icon_for_entry(entry, current_species_id)
	encounter_grid.add_child(icon)
	var probability_field: String = "weight" if _has_property(entry, "weight") else "probability"
	for field: String in ["min_level", "max_level", probability_field]:
		var spin: SpinBox = SpinBox.new()
		spin.custom_minimum_size = Vector2(96 if field != probability_field else 120, 36)
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.min_value = 1.0 if field != "weight" and field != "probability" else 0.0
		spin.max_value = 1000000.0 if field == "weight" else 100.0
		spin.value = float(_read_property(entry, field, 1))
		spin.tooltip_text = field.replace("_", " ").capitalize()
		spin.value_changed.connect(func(value: float) -> void: _write_property(entry, field, int(value)))
		encounter_grid.add_child(spin)
	var percentage: Label = Label.new()
	var row_weight: float = float(_read_property(entry, probability_field, 0))
	percentage.text = ("%.1f%%" % (row_weight * 100.0 / total_weight)) if total_weight > 0.0 else "—"
	percentage.tooltip_text = "Proporción derivada del peso total; no se guarda como porcentaje."
	percentage.custom_minimum_size = Vector2(64, 36)
	percentage.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	encounter_grid.add_child(percentage)
	var delete: Button = Button.new()
	delete.text = "Remove"
	delete.custom_minimum_size = Vector2(76, 36)
	delete.pressed.connect(func() -> void: _remove_entry(index))
	encounter_grid.add_child(delete)

func _icon_for_entry(entry: Object, species_id: int = 0) -> Texture2D:
	if species_icon_by_id.has(species_id):
		return species_icon_by_id[species_id] as Texture2D
	for property: String in ["icon", "icon_sprite", "species_icon"]:
		if _has_property(entry, property):
			var value: Variant = entry.get(property)
			var icon: Texture2D = _first_frame_texture(value)
			if icon != null:
				return icon
	return null

func _entries(table: Object) -> Array:
	for property: String in ["entries", "encounters", "grass_entries"]:
		if _has_property(table, property):
			var value: Variant = table.get(property)
			if value is Array:
				return value as Array
	return []

func _create_table() -> void:
	# Assignment is intentionally done through the legacy MapAttributes property.
	# Projects with a typed WildEncounterTable resource should override this factory.
	if selected_map.is_empty():
		return
	var attrs: Object = selected_map.get("attributes") as Object
	if not is_instance_valid(attrs):
		_clear_selection()
		return
	if _has_property(attrs, "grass_encounters"):
		# Do not create an untyped resource: grass_encounters is typed WildEncounterTable.
		if not ClassDB.class_exists("WildEncounterTable"):
			table_state.text = "Cannot create table: WildEncounterTable class was not found."
			return
		var table: Object = ClassDB.instantiate("WildEncounterTable") as Object
		if not is_instance_valid(table):
			table_state.text = "Cannot create table: WildEncounterTable could not be instantiated."
			return
		_write_property(attrs, "grass_encounters", table)
		selected_table = table
		_render_table()

func _remove_table() -> void:
	if selected_map.is_empty():
		return
	var attrs: Object = selected_map.get("attributes") as Object
	if not is_instance_valid(attrs):
		_clear_selection()
		return
	if _has_property(attrs, "grass_encounters"):
		_write_property(attrs, "grass_encounters", null)
	selected_table = null
	_render_table()

func _add_row() -> void:
	if not is_instance_valid(selected_table):
		selected_table = null
		return
	# Keep this local as an untyped Array: it is the table's actual property,
	# which may be Array[WildEncounterEntry]. Do not append a Control, a script,
	# or a generic Resource to that typed array. In particular, ClassDB can return
	# a GDScript object for a class_name resource instead of an entry instance.
	var entries: Array = _entries(selected_table)
	var entry: Resource = _new_entry_for_array(entries)
	if entry == null:
		table_state.text = "Cannot add entry: WildEncounterEntry resource class was not found."
		return
	var species_field: String = "species_id" if _has_property(entry, "species_id") else "species"
	var probability_field: String = "weight" if _has_property(entry, "weight") else "probability"
	_write_property(entry, species_field, species_values[0] if not species_values.is_empty() else 0)
	_write_property(entry, "min_level", 1)
	_write_property(entry, "max_level", 1)
	_write_property(entry, probability_field, 1)
	# The value is now a real instance created from the array's typed script, so
	# this push is accepted by Array[WildEncounterEntry].
	entries.append(entry)
	_render_table()

func _new_entry_for_array(entries: Array) -> Resource:
	# Godot 4.7.1 exposes the typed script for a scripted TypedArray, but does
	# expose a typed native-class lookup here. Use the script as the
	# authoritative factory so the result is a real WildEncounterEntry Resource accepted by
	# Array[WildEncounterEntry].
	var typed_script: Script = entries.get_typed_script()
	if typed_script != null:
		var scripted_value: Variant = typed_script.new()
		if scripted_value is Resource:
			return scripted_value as Resource
		return null
	# Untyped legacy tables still use the registered entry class. Never weaken a
	# typed table with an unrelated generic resource, which would be rejected by its array.
	if ClassDB.class_exists("WildEncounterEntry"):
		var legacy_value: Object = ClassDB.instantiate("WildEncounterEntry") as Object
		if legacy_value is Resource:
			return legacy_value as Resource
	return null

func _remove_entry(index: int) -> void:
	if not is_instance_valid(selected_table):
		selected_table = null
		_render_table()
		return
	var entries: Array = _entries(selected_table)
	if index >= 0 and index < entries.size():
		entries.remove_at(index)
	_render_table()

func _clear_selection() -> void:
	selected_map = {}
	selected_table = null
	selected_scene_instance = null
	if map_path_label != null:
		map_path_label.text = ""
	if attributes_text != null:
		attributes_text.text = ""
	_render_table()

func _has_property(target: Object, property_name: String) -> bool:
	if not is_instance_valid(target):
		return false
	for info: Dictionary in target.get_property_list():
		if str(info.get("name", "")) == property_name:
			return true
	return false

func _read_property(target: Object, property_name: String, fallback: Variant) -> Variant:
	return target.get(property_name) if is_instance_valid(target) and _has_property(target, property_name) else fallback

func _write_property(target: Object, property_name: String, value: Variant) -> bool:
	if is_instance_valid(target) and _has_property(target, property_name):
		target.set(property_name, value)
		return true
	return false

# Keep Godot's virtual property hooks valid even though this editor has no
# dynamic properties of its own. Data access uses the explicitly named
# helpers above so these signatures cannot collide with helper arguments.
func _get(_property: StringName) -> Variant:
	return null

func _set(_property: StringName, _value: Variant) -> bool:
	return false
