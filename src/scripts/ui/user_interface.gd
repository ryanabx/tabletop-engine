class_name UserInterface
extends Control

var coordinates_labels: Array
@onready var game_name_label: Label = $VBoxContainer/GameNameLabel
@onready var menu_bar: MenuBar = $VBoxContainer/TitleBar/HBoxContainer/MenuBar
@onready var fps_counter: Label = $VBoxContainer/TitleBar/HBoxContainer/FPSCounter

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	SignalManager.game_percent_loaded.connect(update_loading_percent)
	SignalManager.game_load_started.connect(show_loading)
	SignalManager.game_load_finished.connect(hide_loading)
	update_bar_color()
	coordinates_labels.append(Label.new())
	add_child(coordinates_labels[0])

func show_loading() -> void:
	print("Game load started")
	$LoadingBarContainer.show()

func hide_loading() -> void:
	print("Game load finished")
	$LoadingBarContainer.hide()

func update_loading_percent(pc: float) -> void:
	print("Game load at ",pc)
	$LoadingBarContainer/VBoxContainer/LoadingBar.value = pc * 100.0

func peer_connected(_id: int) -> void:
	update_bar_color()

func update_bar_color() -> void:
	if multiplayer != null and multiplayer.is_server() and multiplayer.multiplayer_peer is WebSocketMultiplayerPeer:
		if multiplayer.get_peers().size() > 0:
			$VBoxContainer/TitleBar.get_theme_stylebox("panel").bg_color = Color8(39, 61, 42)
		else:
			$VBoxContainer/TitleBar.get_theme_stylebox("panel").bg_color = Color8(62, 99, 67)
	elif not multiplayer.is_server():
		$VBoxContainer/TitleBar.get_theme_stylebox("panel").bg_color = Color8(39, 47, 61)

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

var drag_window: bool = false
var start_position: Vector2 = Vector2.ZERO
	
	
# func _input(event: InputEvent) -> void:
# 	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
# 		var screen_position = get_viewport().get_screen_transform() * get_viewport().get_mouse_position()
# 		print("Mouse released at ",screen_position)
# 		drag_window = false
# 	elif event is InputEventMouseMotion and drag_window:
# 		DisplayServer.window_set_position(DisplayServer.window_get_position() + Vector2i(get_global_mouse_position() - start_position))

# func _on_title_bar_gui_input(event:InputEvent) -> void:
# 	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
# 		var screen_position = get_viewport().get_screen_transform() * get_viewport().get_mouse_position()
# 		print("Mouse clicked at ",screen_position)
# 		drag_window = true
# 		start_position = get_global_mouse_position()


func _on_multiplayer_button_pressed() -> void:
	SignalManager.open_multiplayer_menu.emit()
