extends Node2D

class_name SummaryPageMoveLearned

@onready var Cursor: Sprite2D = $Cursor_box
@onready var move_detail_panel: Sprite2D = $MoveInfo
@onready var PkmnIcon: Sprite2D = $MoveInfo/Icon
@onready var Category: Sprite2D = $MoveInfo/Category/Category_sprite
@onready var Power: Label = $MoveInfo/Power/Power_Number
@onready var Presision: Label = $MoveInfo/Presision/Percent
@onready var move_description: Label = $MoveInfo/Move_Description
