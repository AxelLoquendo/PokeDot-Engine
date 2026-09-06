extends Node2D

class_name SummaryPageMoveDetail

@onready var Cursor: Sprite2D = $Cursor_box
@onready var PkmnIcon: Sprite2D = $Move_Detail/Icon
@onready var Category: Sprite2D = $Move_Detail/Category/Category_sprite
@onready var Power: Label = $Move_Detail/Power/Power_Number
@onready var Presision: Label = $Move_Detail/Presision/Percent
@onready var move_description: Label = $Move_Detail/Move_Description
