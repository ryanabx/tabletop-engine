class_name UserInterface
extends Control

var coordinates_labels: Array
# @onready var fps_counter: Label = %FPSCounter
@onready var game_info: Label = %GameInfo

@onready var padding_panel: Panel = $PaddingPanel

@onready var input_mode_button: Button = %InputModeButton

var game_name: String = "untitled"
var game_ip_addr: String = "local"

var board: Board = null

@onready var image_1 := preload("res://src/resources/assets/ui/move.svg")
@onready var image_2 := preload("res://src/resources/assets/ui/cursor.svg")


@onready var input_mode_textures: Array[Texture2D] = [
    image_1, image_2
]

func _ready() -> void:
    SignalManager.game_percent_loaded.connect(update_loading_percent)
    SignalManager.game_load_started.connect(show_loading)
    SignalManager.game_load_finished.connect(hide_loading)
    SignalManager.orientation_changed.connect(orientation_changed)
    orientation_changed()

func orientation_changed() -> void:
    padding_panel.custom_minimum_size.y = Globals.safe_margin_t + 2

func show_loading() -> void:
    print("Game load started")
    $SafeMargins/LoadingBarContainer.show()

func hide_loading(_board: Board) -> void:
    board = _board
    print("Game load finished")
    $SafeMargins/LoadingBarContainer.hide()

func update_loading_percent(pc: float) -> void:
    print("Game load at ",pc)
    %LoadingBar.value = pc * 100.0

func _process(_delta: float) -> void:
    # fps_counter.text = str(Engine.get_frames_per_second(), " FPS")
    game_info.text = str("Game: ",game_name)
    if Globals.get_current_game() != null:
        game_name = Globals.get_current_game().export_settings().name
    if board != null:
        input_mode_button.icon = input_mode_textures[board.input_mode]
    

var drag_window: bool = false
var start_position: Vector2 = Vector2.ZERO

func _on_multiplayer_button_pressed() -> void:
    SignalManager.open_multiplayer_menu.emit()

func _on_input_setting_pressed() -> void:
    if board.input_mode == Board.InputMode.CAMERA:
        board.input_mode = Board.InputMode.SELECT
        return
    elif board.input_mode == Board.InputMode.SELECT:
        board.input_mode = Board.InputMode.CAMERA
        return
