@tool
extends Resource

class_name CharacterGame

const TILE_SIZE: int = 16
enum ShadowSize { NONE, S, M, L, XL}
@export var walk_speed: float = 4.0
@export var running_speed: float = 8.0

var _shadow_size: ShadowSize = ShadowSize.NONE
@export var shadow_size: ShadowSize = ShadowSize.NONE:
	set(nuevo_valor):
		if _shadow_size != nuevo_valor:
			_shadow_size = nuevo_valor
			emit_changed()

	get:
		return _shadow_size

var _shadow_offset_x: float = -0.5
@export var shadow_offset_x: float = -0.5:
	set(nuevo_valor):
		if _shadow_offset_x != nuevo_valor:
			_shadow_offset_x = nuevo_valor
			emit_changed()

	get:
		return _shadow_offset_x

var _shadow_offset_y: float = 0.0
@export var shadow_offset_y: float = 0.0:
	set(nuevo_valor):
		if _shadow_offset_y != nuevo_valor:
			_shadow_offset_y = nuevo_valor
			emit_changed()

	get:
		return _shadow_offset_y
