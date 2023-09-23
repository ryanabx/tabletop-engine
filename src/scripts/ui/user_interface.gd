class_name UserInterface
extends Control

var coordinates_labels: Array
# @onready var fps_counter: Label = %FPSCounter
@onready var game_info: Label = %GameInfo

@onready var padding_panel: Panel = $PaddingPanel

@onready var input_mode_button: Button = %InputModeButton
@onready var touch_type_button: Button = %TouchTypeButton

@onready var menu_bar: MenuButton = %MenuButton

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
    get_tree().get_root().game_percent_loaded.connect(update_loading_percent)
    get_tree().get_root().game_load_started.connect(show_loading)
    get_tree().get_root().game_load_finished.connect(set_board)
    $SafeMargins.orientation_changed.connect(orientation_changed)
    orientation_changed()
    menu_bar.get_popup().submenu_popup_delay = 0.0

func orientation_changed() -> void:
    padding_panel.custom_minimum_size.y = Global.safe_margin_t + 2

func show_loading() -> void:
    print("Game load started")
    $SafeMargins/LoadingBarContainer.show()

func set_board(_board: Board) -> void:
    board = _board
    print("Game load finished")
    $SafeMargins/LoadingBarContainer.hide()
    setup_menu_bar()

func update_loading_percent(pc: float) -> void:
    print("Game load at ",pc)
    %LoadingBar.value = pc * 100.0

func _process(_delta: float) -> void:
    # fps_counter.text = str(Engine.get_frames_per_second(), " FPS")
    game_info.text = str("Game: ",game_name)
    if board != null:
        game_name = board.game.name
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

# Menu Bar

@onready var player: PopupMenu
@onready var actions: PopupMenu
    

func setup_menu_bar() -> void:
    if player != null:
        player.queue_free()
        await player.tree_exited
    if actions != null:
        actions.queue_free()
        await actions.tree_exited
    player_menu()
    actions_menu()
    tabletop_menu()

func actions_menu() -> void:
    actions = PopupMenu.new()
    actions.index_pressed.connect(run_action)
    actions.name = "Actions"
    for i: String in board.game.get_actions():
        actions.add_item(i)
    menu_bar.get_popup().add_child(actions)
    menu_bar.get_popup().add_submenu_item("Actions", "Actions")


func player_menu() -> void:
    player = PopupMenu.new()
    player.index_pressed.connect(set_player)
    player.name = "Player"
    menu_bar.get_popup().add_child(player)
    menu_bar.get_popup().add_submenu_item("Player", "Player")
    for i: int in range(board.number_of_players):
        player.add_item(str("Player ",i+1))

func tabletop_menu() -> void:
    menu_bar.get_popup().id_pressed.connect(tabletop_pressed)
    menu_bar.get_popup().add_item(str("Exit ", board.game.name), 0)
    if not Global.is_mobile_platform():
        menu_bar.get_popup().add_item("Exit Tabletop Framework", 1)

func set_player(index: int) -> void:
    print("Setting player to ", index)
    board.player_id = index

func run_action(index: int) -> void:
    board.run_action(index)

func tabletop_pressed(id: int) -> void:
    match id:
        0: %FadeRect.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")
        1: get_tree().quit()
