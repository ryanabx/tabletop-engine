class_name GameBoard
extends Node2D

var _parent: Tabletop

@onready var _game_camera: Camera2D = $BoardCamera
	
func _ready() -> void:
	if _parent == null:
		_parent = get_parent() as Tabletop
