class_name UserInterface
extends Control

var coordinates_label: Label
@onready var game_name_label: Label = $PanelContainer/MarginContainer/VBoxContainer/GameNameLabel

func _ready() -> void:
	coordinates_label = Label.new()
	add_child(coordinates_label)

func _process(_delta: float) -> void:
	coordinates_label.position = get_local_mouse_position() + Vector2(20.0, -30.0)
	var coordinates = Globals.get_tabletop().board.get_local_mouse_position()
	coordinates_label.set_text(str(round(coordinates.x),",", round(coordinates.y)))
	
	if Globals.get_tabletop().game != null:
		game_name_label.text = "Current Game: " + Globals.get_tabletop().game.name
	else:
		game_name_label.text = "Current Game: Untitled"
	queue_redraw()
