@tool
extends HBoxContainer

class_name ItemSelector

signal item_changed

var selected_item: Items.ItemId = Items.ItemId.ITEM_NONE
var available_items: Array[ItemData] = []
var button: Button
var popup: PopupMenu
var names: Dictionary = {}

func _ready() -> void:
	button = Button.new()
	button.custom_minimum_size = Vector2(240, 0)
	button.pressed.connect(_on_pressed)
	add_child(button)
	popup = PopupMenu.new()
	popup.id_pressed.connect(_on_selected)
	add_child(popup)
	_populate()
	_update_text()

func _populate() -> void:
	popup.clear()
	names.clear()
	_add_option(0, "NONE")
	for data: ItemData in available_items:
		if data == null:
			continue
		var id: int = int(data.item_id)
		if names.has(id):
			continue
		_add_option(id, data.item_name)
	if not names.has(int(selected_item)):
		_add_option(int(selected_item), "UNKNOWN")

func _add_option(id: int, display_name: String) -> void:
	popup.add_item("[%d] %s" % [id, display_name], id)
	names[id] = display_name

func _on_pressed() -> void:
	var rect: Rect2 = button.get_global_rect()
	popup.popup(Rect2(rect.position + Vector2(0, rect.size.y), Vector2(270, 0)))

func _on_selected(id: int) -> void:
	selected_item = id as Items.ItemId
	_update_text()
	item_changed.emit()

func _update_text() -> void:
	if button != null:
		button.text = "[%d] %s" % [int(selected_item), str(names.get(int(selected_item), "UNKNOWN"))]
