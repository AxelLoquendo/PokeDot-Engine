extends Node2D  
  
@export var gender_option: GenderOption  
var selection: int = 0  # 0 boy, 1 girl  
var character_data: CharacterPlayer  
var _dialog_lock: bool = false  

func _ready() -> void:  
	$NombreInput.visible = false
	character_data = CharacterPlayer.new()  
	_cargar_textura($Male/Boy_OW, gender_option.boy_id)  
	_cargar_textura($Female/Girl_OW, gender_option.girl_id)  
	_cargar_trainer_sprite($Male/Boy, gender_option.boy_id)  
	_cargar_trainer_sprite($Female/Girl, gender_option.girl_id)  
	_aplicar_seleccion_visual()
  
func _unhandled_input(event: InputEvent) -> void:  
	if _dialog_lock:  
		return  
	if event.is_action_pressed("Right") and selection != 0:  
		selection = 0  
		_aplicar_seleccion_visual()  
	elif event.is_action_pressed("Left") and selection != 1:  
		selection = 1  
		_aplicar_seleccion_visual()  
	elif event.is_action_pressed("buttonA"):  
		_confirmar()  
  
func _aplicar_seleccion_visual() -> void:  
	character_data.gender = selection  
	character_data.sprite_overworld = gender_option.resolve(selection)  
  
	if selection == 0:  
		$Male_anim.play("Seleccionado")  
		$Female_anim.play("No_Seleccionado")  
		$Male.modulate = Color(1, 1, 1)  
		$Female.modulate = Color(0.6, 0.6, 0.6)
		$Female/Girl_OW.play("idle_down")
		$Male/Boy_OW.play("idle_walk_down")
	else:  
		$Female_anim.play("Seleccionado")  
		$Male_anim.play("No_Seleccionado")  
		$Female.modulate = Color(1, 1, 1)  
		$Male.modulate = Color(0.6, 0.6, 0.6)
		$Male/Boy_OW.play("idle_down")
		$Female/Girl_OW.play("idle_walk_down")
	$AudioStreamPlayer.play()
  
## Replica la lógica de reemplazo de atlas de CharacterController._actualizar_sprite(),  
## pero aplicada directamente a un AnimatedSprite2D estático de esta escena.  
func _cargar_textura(sprite: AnimatedSprite2D, id: EventObjects.PlayerID) -> void:  
	if not EventObjects.player_sprites.has(id):  
		return  
	var ruta_sprite: String = EventObjects.player_sprites[id]  
	if ruta_sprite.is_empty() or not ResourceLoader.exists(ruta_sprite):  
		push_warning("Sprite no encontrado: " + ruta_sprite)  
		return  
  
	var textura: Texture2D = load(ruta_sprite) as Texture2D  
	if not textura:  
		return  
  
	# Cada AnimatedSprite2D necesita su propia copia de SpriteFrames,  
	# de lo contrario reemplazar el atlas de uno afecta al otro.  
	var frames: SpriteFrames = sprite.sprite_frames  
	if not frames:  
		return  
	frames = frames.duplicate(true) as SpriteFrames  
  
	for anim_nombre: String in frames.get_animation_names():  
		for i: int in range(frames.get_frame_count(anim_nombre)):  
			var original: Texture2D = frames.get_frame_texture(anim_nombre, i)  
			if original is AtlasTexture:  
				var atlas: AtlasTexture = original.duplicate()  
				atlas.atlas = textura  
				frames.set_frame(anim_nombre, i, atlas, frames.get_frame_duration(anim_nombre, i))  
			else:  
				frames.set_frame(anim_nombre, i, textura, frames.get_frame_duration(anim_nombre, i))  
  
	sprite.sprite_frames = frames  
	sprite.play("idle_down")  
  
func _cargar_trainer_sprite(sprite: Sprite2D, id: EventObjects.PlayerID) -> void:  
	if not EventObjects.trainer_sprites.has(id):  
		return  
	var ruta: String = EventObjects.trainer_sprites[id]  
	if ruta.is_empty() or not ResourceLoader.exists(ruta):  
		push_warning("Trainer sprite no encontrado: " + ruta)  
		return  
	sprite.texture = load(ruta) as Texture2D
  
func _confirmar() -> void:  
	_dialog_lock = true  
	var box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box") as DialogueBox  
	if box == null:  
		_dialog_lock = false  
		return  
	box.choice_selected.connect(_on_confirmado, CONNECT_ONE_SHOT)  
	DialogueManager.show_texts(["¿Confirmas este personaje?"], "", null, ["Sí", "No"])  
  
func _on_confirmado(choice: String) -> void:  
	_dialog_lock = false  
	if choice == "0":  
		_pedir_nombre()  
  
func _pedir_nombre() -> void:
	$NombreInput.visible = true
	var fuente: FontFile = load("res://pokemon-emerald-pro.ttf") as FontFile  
	if fuente:  
		$NombreInput.add_theme_font_override("font", fuente)  
		$NombreInput.add_theme_font_size_override("font_size", 32)  
	$NombreInput.visible = true  
	$NombreInput.text = ""  
	$NombreInput.grab_focus()  
	if not $NombreInput.text_submitted.is_connected(_on_nombre_escrito):  
		$NombreInput.text_submitted.connect(_on_nombre_escrito, CONNECT_ONE_SHOT)
  
func _on_nombre_escrito(texto: String) -> void:  
	$NombreInput.visible = false  
	if texto.strip_edges().is_empty():  
		_pedir_nombre() # vuelve a pedir si está vacío  
		return  
	_confirmar_nombre(texto.strip_edges())  
  
func _confirmar_nombre(nombre: String) -> void:  
	var box: DialogueBox = get_tree().get_first_node_in_group("dialogue_box") as DialogueBox  
	if box == null:  
		NameResult(nombre)  
		return  
	box.choice_selected.connect(_on_nombre_confirmado.bind(nombre), CONNECT_ONE_SHOT)  
	DialogueManager.show_texts(["¿Tu nombre es %s?" % nombre], "", null, ["Sí", "No"])  
  
func _on_nombre_confirmado(choice: String, nombre: String) -> void:  
	if choice == "0":  
		NameResult(nombre)  
	else:  
		_pedir_nombre()

func NameResult(nombre: String) -> void:  
	SaveManager.pending_new_character = {  
		"name": nombre,  
		"gender": character_data.gender,  
		"sprite_overworld": int(character_data.sprite_overworld),  
		"trainer_id": int(randi() % 10000), 
		"created_at": Time.get_date_string_from_system() 
	}
	TransicionManager.cambiar_escena("res://data_core/map/position_game/gestor_inicio.tscn")
