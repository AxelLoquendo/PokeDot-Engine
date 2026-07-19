extends Node
class_name EventObjects

# Identificadores para NPCs
enum NpcID {
	NONE,
	OBJ_EVENT_GFX_PROF_OAK,
}

# Identificadores para Protagonistas
enum PlayerID {
	NONE,
	OBJ_EVENT_GFX_LUCAS_DP,
	OBJ_EVENT_GFX_LUCIA_DP,
	OBJ_EVENT_GFX_NATE_NB,
	OBJ_EVENT_GFX_RISA_NB,
}

# Biblioteca de sprites de NPCs
const npc_sprites: Array[String] = [
	".",
	"res://game/graphics_eb/overworld/player/male/kael/normal.png"
]

# Biblioteca de sprites de Jugadores
const player_sprites: Array[String] = [
	".",
	".",
	".",
	"res://graphics/overworld/player/male/nate/normal.png",
	"res://game/graphics_eb/overworld/player/male/kael/normal.png"
]

static var casillas_ocupadas: Dictionary = {}

static func registrar_casilla(casilla: Vector2i, quien: Node) -> void:
	casillas_ocupadas[casilla] = quien

static func liberar_casilla(casilla: Vector2i) -> void:
	if casillas_ocupadas.has(casilla):
		casillas_ocupadas.erase(casilla)

static func hay_otro_en_casilla(casilla: Vector2i, yo: Node) -> bool:
	return casillas_ocupadas.has(casilla) and casillas_ocupadas[casilla] != yo
