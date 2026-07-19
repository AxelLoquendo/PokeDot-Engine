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
	# Valtherion
	OBJ_EVENT_GFX_KAEL_EB,
	OBJ_EVENT_GFX_KAIDA_EB,
	# Kanto
	OBJ_EVENT_GFX_RED_FRLG,
	OBJ_EVENT_GFX_LEAF_FRLG,
	# Jotho
	OBJ_EVENT_GFX_ECO_HGSS,
	OBJ_EVENT_GFX_CRISTI_GPC,
	OBJ_EVENT_GFX_LYRA_HGSS,
	# Hoenn
	OBJ_EVENT_GFX_BRUNO_RSB,
	OBJ_EVENT_GFX_AURA_RSB,
	# Sinnoh
	OBJ_EVENT_GFX_LEON_DP,
	OBJ_EVENT_GFX_MAYA_DP,
	# Teselia/Unova
	OBJ_EVENT_GFX_LUCHO_BW,
	OBJ_EVENT_GFX_LIZA_BW,
	OBJ_EVENT_GFX_RISSO_B2W2,
	OBJ_EVENT_GFX_NANCI_B2W2,
	
}

# Biblioteca de sprites de NPCs
const npc_sprites: Array[String] = [
	".",
	"res://game/graphics_eb/overworld/player/male/kael/normal.png"
]

# Biblioteca de sprites de Jugadores
const player_sprites: Array[String] = [
	".",
	"res://game/graphics_eb/overworld/player/male/kael/normal.png",
	"res://game/graphics_eb/overworld/player/female/kaida/normal.png",
	"res://graphics/overworld/player/male/red/normal.png",
	"res://graphics/overworld/player/female/leaf/normal.png",
	"res://graphics/overworld/player/male/eco/normal.png",
	"res://graphics/overworld/player/female/cristi/normal.png",
	"res://graphics/overworld/player/female/lyra/normal.png",
	"res://graphics/overworld/player/male/bruno/normal.png",
	"res://graphics/overworld/player/female/aura/normal.png",
	"res://graphics/overworld/player/male/leon/normal.png",
	"res://graphics/overworld/player/female/maya/normal.png",
	"res://graphics/overworld/player/male/lucho/normal.png",
	"res://graphics/overworld/player/female/liza/normal.png",
	"res://graphics/overworld/player/male/risso/normal.png",
	"res://graphics/overworld/player/female/nanci/normal.png",
]

static var casillas_ocupadas: Dictionary = {}

static func registrar_casilla(casilla: Vector2i, quien: Node) -> void:
	casillas_ocupadas[casilla] = quien

static func liberar_casilla(casilla: Vector2i) -> void:
	if casillas_ocupadas.has(casilla):
		casillas_ocupadas.erase(casilla)

static func hay_otro_en_casilla(casilla: Vector2i, yo: Node) -> bool:
	return casillas_ocupadas.has(casilla) and casillas_ocupadas[casilla] != yo
