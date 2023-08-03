class_name UserInterface
extends Control

var coordinates_labels: Array
@onready var game_name_label: Label = $VBoxContainer/GameNameLabel
@onready var menu_bar: MenuBar = $VBoxContainer/PanelContainer/HBoxContainer/MenuBar
@onready var fps_counter: Label = $VBoxContainer/PanelContainer/HBoxContainer/FPSCounter

func _ready() -> void:
	coordinates_labels.append(Label.new())
	add_child(coordinates_labels[0])

func _process(_delta: float) -> void:
	fps_counter.text = str(Engine.get_frames_per_second(), "fps")
	coordinates_labels[0].position = get_local_mouse_position() + Vector2(20.0, -30.0)
	if Globals.get_current_tabletop() == null:
		return
	var coordinates = Globals.get_current_tabletop().get_local_mouse_position()
	coordinates_labels[0].set_text(str(round(coordinates.x),",", round(coordinates.y)))
	
	if Globals.get_current_game() != null:
		game_name_label.text = "Current Game: " + Globals.get_current_game().name
	else:
		game_name_label.text = "No Game Loaded"
	queue_redraw()
