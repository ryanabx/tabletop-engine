class_name UserInterface
extends Control

@onready var coordinates_label = $Coordinates

func set_game_name(name: String) -> void:
	pass

func _process(delta: float) -> void:
	coordinates_label.position = get_local_mouse_position() + Vector2(20.0, -30.0)
	var coordinates = Globals.get_board().get_local_mouse_position()
	coordinates_label.set_text(str(round(coordinates.x),",", round(coordinates.y)))