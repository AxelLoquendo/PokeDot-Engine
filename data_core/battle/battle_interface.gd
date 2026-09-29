extends RefCounted
class_name BattleInterface
## Helpers de UI de combate: barras de PS, nombres, niveles, sprites.


static func refresh_slot(
	layout: BattleUILayout,
	battler: BattleBattler,
	animate_hp: bool = true
) -> void:
	if layout == null or battler == null:
		return
	var view: BattleUILayout.SlotView = layout.slot(battler.is_player_side, battler.slot_index)
	if view == null:
		return

	var mon: PokemonInstance = battler.pokemon
	if mon == null:
		_hide_view(view)
		return

	if view.name_label != null:
		view.name_label.text = battler.get_display_name()
	if view.level_label != null:
		view.level_label.text = "Nv.%d" % mon.level

	var max_hp: int = battler.get_max_hp()
	var cur_hp: int = battler.get_current_hp()
	if bool(battler.get_meta("is_dynamax", false)):
		max_hp = int(battler.get_meta("dynamax_hp_max", max_hp))
		cur_hp = int(battler.get_meta("dynamax_hp_current", cur_hp))

	var ratio: float = 0.0 if max_hp <= 0 else clampf(float(cur_hp) / float(max_hp), 0.0, 1.0)
	if view.hp_bar != null:
		await _set_hp_bar(view.hp_bar, ratio, animate_hp)

	if view.hp_label != null and battler.is_player_side:
		view.hp_label.text = "%d/%d" % [cur_hp, max_hp]

	if view.sprite != null:
		_load_sprite(view.sprite, mon, battler.is_player_side)


static func _set_hp_bar(hp_bar: Node, ratio: float, animate: bool) -> void:
	var max_w: float = 48.0
	if hp_bar is ColorRect:
		var bar: ColorRect = hp_bar as ColorRect
		var target_w: float = max_w * ratio
		bar.color = _hp_color(ratio)
		if animate:
			var tw: Tween = bar.create_tween()
			tw.tween_property(bar, "size:x", target_w, 0.35)
			await tw.finished
		else:
			bar.size.x = target_w
	elif hp_bar is ProgressBar:
		var pb: ProgressBar = hp_bar as ProgressBar
		pb.max_value = 100.0
		if animate:
			var tw2: Tween = pb.create_tween()
			tw2.tween_property(pb, "value", ratio * 100.0, 0.35)
			await tw2.finished
		else:
			pb.value = ratio * 100.0
	elif "scale" in hp_bar:
		if animate:
			var tw3: Tween = hp_bar.create_tween()
			tw3.tween_property(hp_bar, "scale:x", ratio, 0.35)
			await tw3.finished
		else:
			hp_bar.scale.x = ratio


static func _hp_color(ratio: float) -> Color:
	if ratio > 0.5:
		return Color(0.35, 0.85, 0.35)
	if ratio > 0.2:
		return Color(0.95, 0.85, 0.2)
	return Color(0.9, 0.25, 0.2)


static func _load_sprite(sprite: Sprite2D, mon: PokemonInstance, is_player: bool) -> void:
	if mon == null or sprite == null:
		return
	var path: String = ""
	if mon.has_method("get_battle_sprite_path"):
		path = str(mon.get_battle_sprite_path(is_player))
	else:
		var sid: int = int(mon.species_id)
		var side: String = "back" if is_player else "front"
		path = "res://assets/pokemon/%d/%s.png" % [sid, side]
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path) as Texture2D
	if tex != null:
		sprite.texture = tex


static func _hide_view(view: BattleUILayout.SlotView) -> void:
	if view == null:
		return
	if view.sprite is CanvasItem:
		(view.sprite as CanvasItem).visible = false
	if view.hp_box is CanvasItem:
		(view.hp_box as CanvasItem).visible = false
