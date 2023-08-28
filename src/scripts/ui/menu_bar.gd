extends MenuButton

@onready var menu: MenuButton = self
@onready var player: PopupMenu
@onready var actions: PopupMenu

var board: Board = null

func _ready() -> void:
	tabletop_menu()
	SignalManager.game_load_finished.connect(set_board)

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

# func server_menu() -> void:
# 	var sv_menu: PopupMenu = PopupMenu.new()
# 	if multiplayer.is_server():
# 		sv_menu.name = "Disband Server"
# 	else:
# 		sv_menu.name = "Disconnect from Server"
# 	sv_menu.about_to_popup.connect(_disconnect_from_server)
# 	menu.add_child(sv_menu)

# func _disconnect_from_server() -> void:
# 	print("Disconnect from server")
# 	MultiplayerManager.disband()
# 	get_tree().reload_current_scene()

func actions_menu() -> void:
	actions = PopupMenu.new()
	actions.index_pressed.connect(run_action)
	actions.name = "Actions"
	for i in board.game.actions:
		actions.add_item(i.name)
	menu.get_popup().add_child(actions)
	menu.get_popup().add_submenu_item("Actions", "Actions")


func player_menu() -> void:
	player = PopupMenu.new()
	player.index_pressed.connect(set_player)
	player.name = "Player"
	menu.get_popup().add_child(player)
	menu.get_popup().add_submenu_item("Player", "Player")
	for i in range(board.game.player.max):
		player.add_item(str("Player ",i+1))

func tabletop_menu() -> void:
	menu.get_popup().id_pressed.connect(tabletop_pressed)
	menu.get_popup().add_item("Main Menu", 0)
	if not Utils.is_mobile_platform():
		menu.get_popup().add_item("Quit", 1)

func set_player(index: int) -> void:
	Player.set_id(index)

func run_action(index: int) -> void:
	SignalManager.run_action.emit(index)

func tabletop_pressed(id: int) -> void:
	match id:
		0: SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")
		1: get_tree().quit()
