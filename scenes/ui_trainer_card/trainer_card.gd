extends CanvasLayer  
  
@export var card_male: Texture2D  
@export var bg_male: Texture2D  
@export var card_female: Texture2D  
@export var bg_female: Texture2D  
  
@onready var sprite_fondo: Sprite2D = $Fondo  
@onready var sprite_card: Sprite2D = $Card  
@onready var sprite_trainer: Sprite2D = $Trainer  
  
var is_open: bool = true

func _ready() -> void:  
	var jugador: CharacterController = get_tree().get_first_node_in_group("player") as CharacterController  
	var datos_jugador: CharacterPlayer = jugador.character_data as CharacterPlayer if jugador else null  
  
	var gender: int = datos_jugador.gender if datos_jugador else 0  
	var sprite_id: int = int(datos_jugador.sprite_overworld) if datos_jugador else 0  
	var segundos: float = SaveManager.get_play_seconds()  
  
	_aplicar_textura(gender)  
	_cargar_trainer_sprite(sprite_trainer, sprite_id as EventObjects.PlayerID)  
	_rellenar_datos_desde_jugador(datos_jugador, segundos)  
	set_process_input(true)
  
func _input(event: InputEvent) -> void:  
	if event.is_echo() or not event.is_pressed():  
		return  
	if event.is_action_pressed("buttonB"):  
		is_open = false  
		queue_free()  
		get_viewport().set_input_as_handled()

func _aplicar_textura(gender: int) -> void:  
	if gender == 0:  
		sprite_fondo.texture = bg_male  
		sprite_card.texture = card_male  
	else:  
		sprite_fondo.texture = bg_female  
		sprite_card.texture = card_female  
  
func _cargar_trainer_sprite(sprite: Sprite2D, id: EventObjects.PlayerID) -> void:  
	if not EventObjects.trainer_sprites.has(id):  
		return  
	var ruta: String = EventObjects.trainer_sprites[id]  
	if ruta.is_empty() or not ResourceLoader.exists(ruta):  
		push_warning("Trainer sprite no encontrado: " + ruta)  
		return  
	sprite.texture = load(ruta) as Texture2D

func _rellenar_datos_desde_jugador(datos_jugador: CharacterPlayer, segundos: float) -> void:  
	var seg: int = int(segundos)  
	$Name.text = "Nombre: %s" % (datos_jugador.name if datos_jugador else "---")  
	$Money.text = "Dinero: %d" % (datos_jugador.money if datos_jugador else 0)  
	$Time.text = "Tiempo: %02d:%02d:%02d" % [seg / 3600.0, (seg % 3600) / 60.0, seg % 60]  
	$Pokedex.text = "Pokedex: ---"  
	$Start.text = "Comienzo: %s" % (datos_jugador.created_at if datos_jugador else "---")  
	var id_entero: int = datos_jugador.trainer_id if datos_jugador else 0  
	$ID.text = "NoID %05d" % id_entero

func _rellenar_datos(datos: Dictionary) -> void:  
	var segundos: int = int(float(datos.get("play_seconds", 0.0)))  
	$Name.text = "Nombre: %s" % str(datos.get("player_name", "---"))  
	$Money.text = "Dinero: %d" % int(datos.get("player_money", 0))  
	$Time.text = "Tiempo: %02d:%02d:%02d" % [segundos / 3600.0, (segundos % 3600) / 60.0, segundos % 60]  
	$Pokedex.text = "Pokedex: ---"
	$Start.text = "Comienzo: %s" % str(datos.get("created_at", "---"))
	var id_entero: int = int(datos.get("player_trainer_id", 0))
	$ID.text = "NoID %05d" % id_entero
