@tool
extends Resource
class_name CharacterGame

const TILE_SIZE: int = 16

enum ShadowSize { NONE, S, M, L, XL }

@export var walk_speed: float = 4.0
@export var running_speed: float = 8.0

var _shadow_size: ShadowSize = ShadowSize.NONE
@export var shadow_size: ShadowSize = ShadowSize.NONE:
	set(value):
		if _shadow_size != value:
			_shadow_size = value
			emit_changed()
	get:
		return _shadow_size

var _shadow_offset_x: float = -0.5
@export var shadow_offset_x: float = -0.5:
	set(value):
		if _shadow_offset_x != value:
			_shadow_offset_x = value
			emit_changed()
	get:
		return _shadow_offset_x

var _shadow_offset_y: float = 0.0
@export var shadow_offset_y: float = 0.0:
	set(value):
		if _shadow_offset_y != value:
			_shadow_offset_y = value
			emit_changed()
	get:
		return _shadow_offset_y
