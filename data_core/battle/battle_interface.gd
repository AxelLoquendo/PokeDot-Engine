
extends RefCounted
class_name BattleInterface
## Helpers de UI de combate: barras de PS, nombres, niveles, sprites.
## Usa PokemonInstance / PokemonFormResolver (no rutas hardcodeadas a assets/).


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
	if mon == null or battler.is_fainted():
		_hide_view(view)
		return

	_show_view(view)

	if view.name_label != null:
		view.name_label.text = battler.get_display_name()
	if view.level_label != null:
		view.level_label.text = "Nv.%d" % mon.level

	if view.gender_label != null:
		view.gender_label.text = _gender_text(mon)

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
		_load_sprite(view.sprite, mon, battler.is_player_side, battler)

	_update_status_icon(view, mon)


static func _set_hp_bar(hp_bar: Node, ratio: float, animate: bool) -> void:
	var max_w: float = 48.0
	if hp_bar is ColorRect:
		var bar: ColorRect = hp_bar as ColorRect
		var target_w: float = max_w * ratio
		bar.color = _hp_color(ratio)
		if animate and bar.is_inside_tree():
			var tw: Tween = bar.create_tween()
			tw.tween_property(bar, "size:x", target_w, 0.35)
			await tw.finished
		else:
			bar.size.x = target_w
	elif hp_bar is ProgressBar:
		var pb: ProgressBar = hp_bar as ProgressBar
		pb.max_value = 100.0
		if animate and pb.is_inside_tree():
			var tw2: Tween = pb.create_tween()
			tw2.tween_property(pb, "value", ratio * 100.0, 0.35)
			await tw2.finished
		else:
			pb.value = ratio * 100.0
	elif "scale" in hp_bar:
		if animate and hp_bar is Node and (hp_bar as Node).is_inside_tree():
			var tw3: Tween = (hp_bar as Node).create_tween()
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


static func _load_sprite(
	sprite: Sprite2D,
	mon: PokemonInstance,
	is_player: bool,
	battler: BattleBattler = null
) -> void:
	if mon == null or sprite == null:
		return

	# Illusion: mostrar el mon "disfrazado" si el battler tiene meta
	var display_mon: PokemonInstance = mon
	if battler != null and battler.has_meta("illusion_mon"):
		var ill: Variant = battler.get_meta("illusion_mon")
		if ill is PokemonInstance:
			display_mon = ill as PokemonInstance

	var tex: Texture2D = null
	if is_player:
		if display_mon.has_method("get_back_sprite"):
			tex = display_mon.get_back_sprite()
	else:
		if display_mon.has_method("get_front_sprite"):
			tex = display_mon.get_front_sprite()

	# Fallback por si no hay método o textura nula
	if tex == null:
		if is_player:
			tex = PokemonFormResolver.get_back_sprite(display_mon, display_mon.shiny)
		else:
			tex = PokemonFormResolver.get_front_sprite(display_mon, display_mon.shiny)

	if tex == null:
		# Último recurso: ruta legacy (solo si existe)
		var sid: int = int(display_mon.species_id)
		var side: String = "back" if is_player else "front"
		var path: String = "res://assets/pokemon/%d/%s.png" % [sid, side]
		if ResourceLoader.exists(path):
			tex = load(path) as Texture2D

	if tex != null:
		sprite.texture = tex
		sprite.visible = true

	# Offset de especie/forma
	var offset: Vector2 = Vector2.ZERO
	if is_player:
		offset = PokemonFormResolver.get_back_sprite_offset(display_mon)
	else:
		offset = PokemonFormResolver.get_front_sprite_offset(display_mon)
	# Solo aplicar offset extra si el layout guardó posición base
	# (no mover fuera de pantalla si offset es enorme)


static func _gender_text(mon: PokemonInstance) -> String:
	if mon == null:
		return ""
	match mon.gender:
		PokemonData.Gender.MALE:
			return "♂"
		PokemonData.Gender.FEMALE:
			return "♀"
		_:
			return ""


static func _update_status_icon(view: BattleUILayout.SlotView, mon: PokemonInstance) -> void:
	if view == null or view.status_sprite == null or mon == null:
		return
	# Sin atlas dedicado: ocultar si no hay status; dejar texture pre-asignada si hay
	if mon.status == PokemonInstance.Status.NONE:
		view.status_sprite.visible = false
	else:
		view.status_sprite.visible = true


static func _show_view(view: BattleUILayout.SlotView) -> void:
	if view == null:
		return
	if view.sprite is CanvasItem:
		(view.sprite as CanvasItem).visible = true
	if view.hp_box is CanvasItem:
		(view.hp_box as CanvasItem).visible = true


static func _hide_view(view: BattleUILayout.SlotView) -> void:
	if view == null:
		return
	if view.sprite is CanvasItem:
		(view.sprite as CanvasItem).visible = false
	if view.hp_box is CanvasItem:
		(view.hp_box as CanvasItem).visible = false


static func play_cry(layout: BattleUILayout, battler: BattleBattler) -> void:
	if layout == null or battler == null or battler.pokemon == null:
		return
	var view: BattleUILayout.SlotView = layout.slot(battler.is_player_side, battler.slot_index)
	if view == null or view.cry == null:
		return
	var stream: AudioStream = null
	if battler.pokemon.has_method("get_cry"):
		stream = battler.pokemon.get_cry()
	if stream == null:
		stream = PokemonFormResolver.get_cry(battler.pokemon)
	if stream != null:
		view.cry.stream = stream
		view.cry.play()


static func apply_background(layout: BattleUILayout, bg_id: int) -> void:
	if layout == null or layout.bg == null:
		return
	var tex: Texture2D = BattleBackground.get_texture(bg_id as BattleBackground.Background)
	if tex != null:
		layout.bg.texture = tex
