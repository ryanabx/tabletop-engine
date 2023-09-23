class_name UserInterface
extends Control

var coordinates_labels: Array
# @onready var fps_counter: Label = %FPSCounter
@onready var game_info: Label = %GameInfo

@onready var padding_panel: Panel = $PaddingPanel

@onready var input_mode_button: Button = %InputModeButton
@onready var touch_type_button: Button = %TouchTypeButton

var game_name: String = "untitled"
var game_ip_addr: String = "local"

var board: Board = null

@onready var image_1 := preload("res://src/resources/assets/ui/move.svg")
@onready var image_2 := preload("res://src/resources/assets/ui/cursor.svg")


@onready var input_mode_textures: Array[Texture2D] = [
    image_1, image_2
]

@onready var touch_types: Array[String] = [
    "Tap", "Drag"
]

func _ready() -> void:
    GameManager.game_percent_loaded.connect(update_loading_percent)
    GameManager.game_load_started.connect(show_loading)
    GameManager.game_load_finished.connect(hide_loading)
    GameManager.orientation_changed.connect(orientation_changed)
    orientation_changed()

func orientation_changed() -> void:
    padding_panel.custom_minimum_size.y = Global.safe_margin_t + 2

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
    if Global.get_current_game() != null:
        game_name = Global.get_current_game().export_settings().name
    if board != null:
        input_mode_button.icon = input_mode_textures[board.input_mode]
        touch_type_button.text = touch_types[board.touch_type]
    

var drag_window: bool = false
var start_position: Vector2 = Vector2.ZERO

func _on_input_setting_pressed() -> void:
    if board.input_mode == Board.InputMode.CAMERA:
        board.input_mode = Board.InputMode.SELECT
        return
    elif board.input_mode == Board.InputMode.SELECT:
        board.input_mode = Board.InputMode.CAMERA
        return


func _on_touch_type_button_pressed() -> void:
    if board.touch_type == Board.TouchType.DRAG:
        board.touch_type = Board.TouchType.TAP
        return
    elif board.touch_type == Board.TouchType.TAP:
        board.touch_type = Board.TouchType.DRAG
        return
