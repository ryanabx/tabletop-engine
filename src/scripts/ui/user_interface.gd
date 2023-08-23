class_name UserInterface
extends Control

var coordinates_labels: Array
@onready var menu_bar: MenuBar = $TitleBar/HBoxContainer/MenuBar
@onready var fps_counter: Label = $BottomBar/HBoxContainer/FPSCounter
@onready var game_info: Label = $BottomBar/HBoxContainer/GameInfo

var game_name: String = "untitled"
var game_ip_addr: String = "local"

var board: Board = null

func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	SignalManager.game_percent_loaded.connect(update_loading_percent)
	SignalManager.game_load_started.connect(show_loading)
	SignalManager.game_load_finished.connect(hide_loading)
	update_bar_color()

func show_loading() -> void:
	print("Game load started")
	$LoadingBarContainer.show()

func hide_loading(_board: Board) -> void:
	board = _board
	print("Game load finished")
	$LoadingBarContainer.hide()

func update_loading_percent(pc: float) -> void:
	print("Game load at ",pc)
	$LoadingBarContainer/VBoxContainer/LoadingBar.value = pc * 100.0

func peer_connected(_id: int) -> void:
	update_bar_color()

func update_bar_color() -> void:
	if multiplayer != null and multiplayer.is_server() and multiplayer.multiplayer_peer is WebRTCMultiplayerPeer:
		if multiplayer.get_peers().size() > 0:
			$TitleBar.get_theme_stylebox("panel").bg_color = Color8(39, 61, 42)
		else:
			$TitleBar.get_theme_stylebox("panel").bg_color = Color8(62, 99, 67)
	elif not multiplayer.is_server():
		$TitleBar.get_theme_stylebox("panel").bg_color = Color8(39, 47, 61)

func _process(_delta: float) -> void:
	fps_counter.text = str(Engine.get_frames_per_second(), "fps")
	game_info.text = str("Game: ",game_name, " | Server: ",game_ip_addr, " | ")
	if Globals.get_current_game() != null:
		game_name = Globals.get_current_game().name

var drag_window: bool = false
var start_position: Vector2 = Vector2.ZERO

func _on_multiplayer_button_pressed() -> void:
	SignalManager.open_multiplayer_menu.emit()
