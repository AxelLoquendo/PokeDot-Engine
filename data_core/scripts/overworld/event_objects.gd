extends Node
class_name EventObjects

var NPC_Deseado: int = 0

enum NpcID {
	NONE,
	OBJ_EVENT_GFX_PROF_OAK,
	OBJ_EVENT_GFX_KAEL,
	OBJ_EVENT_GFX_KAIDA,
}

enum PlayerID {
	NONE,
	# Valtherion
	OBJ_EVENT_GFX_KAEL_EB,
	OBJ_EVENT_GFX_KAIDA_EB,
	# Kanto
	OBJ_EVENT_GFX_RED_FRLG,
	OBJ_EVENT_GFX_LEAF_FRLG,
	# Johto
	OBJ_EVENT_GFX_ECO_HGSS,
	OBJ_EVENT_GFX_CRISTI_GPC,
	OBJ_EVENT_GFX_LYRA_HGSS,
	# Hoenn
	OBJ_EVENT_GFX_BRUNO_RSB,
	OBJ_EVENT_GFX_AURA_RSB,
	# Sinnoh
	OBJ_EVENT_GFX_LEON_DP,
	OBJ_EVENT_GFX_MAYA_DP,
	# Unova
	OBJ_EVENT_GFX_LUCHO_BW,
	OBJ_EVENT_GFX_LIZA_BW,
	OBJ_EVENT_GFX_RISSO_B2W2,
	OBJ_EVENT_GFX_NANCI_B2W2,
}

const npc_sprites: Dictionary = {
	NpcID.NONE: "",
	NpcID.OBJ_EVENT_GFX_PROF_OAK: "res://graphics/overworld/npc/profesor_oak.png",
	NpcID.OBJ_EVENT_GFX_KAEL: "res://game/graphics_eb/overworld/player/male/kael/normal.png",
	NpcID.OBJ_EVENT_GFX_KAIDA: "res://game/graphics_eb/overworld/player/female/kaida/normal.png",
}

const player_sprites: Dictionary = {
	PlayerID.NONE: "",
	PlayerID.OBJ_EVENT_GFX_KAEL_EB: "res://game/graphics_eb/overworld/player/male/kael/normal.png",
	PlayerID.OBJ_EVENT_GFX_KAIDA_EB: "res://game/graphics_eb/overworld/player/female/kaida/normal.png",
	PlayerID.OBJ_EVENT_GFX_RED_FRLG: "res://graphics/overworld/player/male/red/normal.png",
	PlayerID.OBJ_EVENT_GFX_LEAF_FRLG: "res://graphics/overworld/player/female/leaf/normal.png",
	PlayerID.OBJ_EVENT_GFX_ECO_HGSS: "res://graphics/overworld/player/male/eco/normal.png",
	PlayerID.OBJ_EVENT_GFX_CRISTI_GPC: "res://graphics/overworld/player/female/cristi/normal.png",
	PlayerID.OBJ_EVENT_GFX_LYRA_HGSS: "res://graphics/overworld/player/female/lyra/normal.png",
	PlayerID.OBJ_EVENT_GFX_BRUNO_RSB: "res://graphics/overworld/player/male/bruno/normal.png",
	PlayerID.OBJ_EVENT_GFX_AURA_RSB: "res://graphics/overworld/player/female/aura/normal.png",
	PlayerID.OBJ_EVENT_GFX_LEON_DP: "res://graphics/overworld/player/male/leon/normal.png",
	PlayerID.OBJ_EVENT_GFX_MAYA_DP: "res://graphics/overworld/player/female/maya/normal.png",
	PlayerID.OBJ_EVENT_GFX_LUCHO_BW: "res://graphics/overworld/player/male/lucho/normal.png",
	PlayerID.OBJ_EVENT_GFX_LIZA_BW: "res://graphics/overworld/player/female/liza/normal.png",
	PlayerID.OBJ_EVENT_GFX_RISSO_B2W2: "res://graphics/overworld/player/male/risso/normal.png",
	PlayerID.OBJ_EVENT_GFX_NANCI_B2W2: "res://graphics/overworld/player/female/nanci/normal.png",
}

const trainer_sprites: Dictionary = {
	PlayerID.NONE: "",
	PlayerID.OBJ_EVENT_GFX_KAEL_EB: "res://game/graphics_eb/trainers/Kael.png",
	PlayerID.OBJ_EVENT_GFX_KAIDA_EB: "res://game/graphics_eb/trainers/Kaida.png",
}

static var casillas_ocupadas: Dictionary = {}   # Vector2i -> Node
static var casillas_reservadas: Dictionary = {} # Vector2i -> Node


static func registrar_casilla(casilla: Vector2i, quien: Node) -> void:
	casillas_ocupadas[casilla] = quien


static func liberar_casilla(casilla: Vector2i) -> void:
	casillas_ocupadas.erase(casilla)


static func hay_otro_en_casilla(casilla: Vector2i, yo: Node) -> bool:
	return casillas_reservadas.has(casilla) and casillas_reservadas[casilla] != yo


static func reservar_casilla(casilla: Vector2i, quien: Node) -> void:
	casillas_reservadas[casilla] = quien


static func liberar_reserva(casilla: Vector2i) -> void:
	casillas_reservadas.erase(casilla)


static func obtener_personaje_en_casilla(casilla: Vector2i) -> CharacterController:
	if not casillas_ocupadas.has(casilla):
		return null
	var personaje: Variant = casillas_ocupadas[casilla]
	if personaje is CharacterController:
		return personaje as CharacterController
	return null
