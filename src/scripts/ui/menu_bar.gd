extends MenuButton

@onready var menu: MenuButton = self
@onready var player: PopupMenu
@onready var actions: PopupMenu

var board: Board = null

func _ready() -> void:
    get_popup().submenu_popup_delay = 0.0
    GameManager.game_load_finished.connect(set_board)

func set_board(_b: Board) -> void:
    board = _b
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
    menu.get_popup().add_child(actions)
    menu.get_popup().add_submenu_item("Actions", "Actions")


func player_menu() -> void:
    player = PopupMenu.new()
    player.index_pressed.connect(set_player)
    player.name = "Player"
    menu.get_popup().add_child(player)
    menu.get_popup().add_submenu_item("Player", "Player")
    for i: int in range(board.number_of_players):
        player.add_item(str("Player ",i+1))

func tabletop_menu() -> void:
    menu.get_popup().id_pressed.connect(tabletop_pressed)
    menu.get_popup().add_item(str("Exit ", board.game.export_settings().name), 0)
    if not Utils.is_mobile_platform():
        menu.get_popup().add_item("Exit Tabletop Framework", 1)

func set_player(index: int) -> void:
    print("Setting player to ", index)
    board.player_id = index

func run_action(index: int) -> void:
    GameManager.run_action.emit(index)

func tabletop_pressed(id: int) -> void:
    match id:
        0: GameManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")
        1: get_tree().quit()
