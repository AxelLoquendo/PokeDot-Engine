extends Resource
class_name DialogueChoice
@export_group("Visualización")
@export var text: String = ""

@export_group("Lógica")
## ID único para registrar esta elección en el sistema de guardado.
@export var choice_id: String = ""
## ID de la página a la que saltar. Si está vacío, sigue el flujo normal.
@export var next_page_id: String = ""
## (Opcional) Flag requerido para mostrar esta opción.
@export var required_flag: String = ""
