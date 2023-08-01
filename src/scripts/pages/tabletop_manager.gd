class_name TabletopManager
extends Node

@onready var tt_scene: PackedScene = preload("res://src/scenes/game_elements/tabletop.tscn")

# Crucial base operation nodes
@onready var user_interface: UserInterface = $UserInterfaceLayer/UserInterface
@onready var camera_controller: CameraController = $CameraController
@onready var dialogs: Node = $UserInterfaceLayer/Dialogs
@onready var tabletop_spawner = $TabletopSpawner

var current_game: String = ""


func _ready() -> void:
	Globals.set_shared_tabletop_manager(self)

func load_game_config(gc: GameConfig) -> void:
	await remove_tabletop()
	if multiplayer.is_server():
		current_game = gc.name
		print("host_loaded_config")
		tabletop_spawner.call_deferred("spawn",gc.unpack_data())
	

@rpc("any_peer", "call_remote")
func host_loaded_config(game_name: String) -> void:
	current_game = game_name
	print("Host loaded config")
	dialogs.get_node("ImportConfigFileOpen").title = str("Remote user has requested to play ",game_name,". Load the desired config here.")
	dialogs.get_node("ImportConfigFileOpen").popup()

func remove_tabletop() -> void:
	if Globals.get_current_tabletop() != null:
		Globals.get_current_tabletop().queue_free()
		await Globals.get_current_tabletop().tree_exited
	return

func run_action(index: int) -> void:
	var action: Array = Globals.get_current_game().actions[index].actions.duplicate(true)
	for cmd in action:
		await parse_command(cmd)
	print("Action ",Globals.get_current_game().actions[index].name, " parsed.")

func parse_command(cmd: Dictionary) -> void:
	var result: bool = true
	var repeat = cmd.repeat if "repeat" in cmd else 1
	print("Running command ",cmd.cmd)
	for i in range(repeat):
		match cmd.cmd:
			"reset_board":
				result = await cmd_reset_board(cmd)
			"shuffle":
				result = cmd_shuffle(cmd)
			"move_top":
				result = cmd_move_top(cmd)
			_:
				result = false
	print("Command ",cmd.cmd, " returned ",result)

### ACTION COMMANDS ###

func cmd_reset_board(_cmd: Dictionary) -> bool:
	await load_game_config(Globals.get_current_game())
	print("Done resetting board")
	return true

func cmd_shuffle(cmd: Dictionary) -> bool:
	if not "targets" in cmd.args:
		return false
	for group_name in cmd.args.targets:
		var collections = get_tree().get_nodes_in_group(group_name)
		for c in collections:
			c.shuffle()
	return true

func cmd_move_top(cmd: Dictionary) -> bool:
	if not "from" in cmd.args:
		return false
	var from = get_tree().get_first_node_in_group(cmd.args.from)
	if "to" in cmd.args:
		var to = get_tree().get_first_node_in_group(cmd.args.to)
		print("from: ",from, "to: ",to)
		if from.get_num_objects() == 0:
			print("No objects")
			return false
		var piece: Piece = from.get_game_objects()[-1]
		print("Piece name: ",piece.name)
		Globals.get_current_tabletop().board.game_object_manager.stack_objects_to_item([piece], to)
	return true
	
