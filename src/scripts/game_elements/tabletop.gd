class_name Tabletop
extends Node

var game: GameConfig
var coordinate_scale: Vector2

@onready var board: GameBoard = $GameBoard
@onready var game_object_spawner: MultiplayerSpawner = $GameBoard/GameObjectSpawner

func _ready() -> void:
	coordinate_scale = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
	set_up_board_props()
	edit_menu_bar()
	if multiplayer.is_server():
		build_board_objects()

func edit_menu_bar():
	var menu_bar: MenuBar = Globals.get_shared_tabletop_manager().user_interface.menu_bar
	menu_bar.new_game_loaded(game.player.max, game.actions)

func set_up_board_props() -> void:
	if "border" in game.board:
		board.set_border(
			Rect2(
				(Vector2(game.board.border.position.x, game.board.border.position.y) - Vector2(game.board.border.scale.x, game.board.border.scale.y) / 2) * coordinate_scale,
				Vector2(game.board.border.scale.x, game.board.border.scale.y) * coordinate_scale
			)
		)
	# Set up game bg
	if "background_image" in game.board and game.board.background_image != "":
		board.board_texture_string = game.board.background_image
		board.set_board_texture()

func _process(_delta: float) -> void:
	Globals.get_shared_tabletop_manager().camera_controller.camera.position = Globals.get_shared_tabletop_manager().camera_controller.camera.position.clamp(board.get_border().position, board.get_border().end)

func build_board_objects() -> void:
	for item in game.objects:
		process_object(item)

func process_object(obj: Dictionary) -> void:
	# Use templates if they exist
	if "template" in obj:
		obj.merge(game.templates[obj.template])
	
	# Handle for loops
	if "for" in obj:
		var total_objs: int = 1
		for x in obj["for"].keys():
			total_objs = total_objs * obj["for"][x].size()
		for i in range(total_objs):
			var repls: Dictionary = {}
			var t: int = 1
			for key in obj["for"].keys():
				var size = obj["for"][key].size()
				repls[key] = obj["for"][key][(floori(i as float/t)) % size]
				t = t * size
			var _o: Dictionary = make_object_dict(obj, repls)
			new_object(_o)
	else:
		new_object(obj)
	
	# Create objects

func make_object_dict(original: Dictionary, repls: Dictionary) -> Dictionary:
	var obj: Dictionary = original.duplicate(true)
	for key in obj.keys():
		for repl in repls.keys():
			if typeof(obj[key]) == TYPE_STRING:
				obj[key] = obj[key].replacen(repl, repls[repl])
	return obj
	
func new_object(obj: Dictionary) -> void:
	var amount: int = obj.repeat if "repeat" in obj else 1
	obj.coordinate_scale = coordinate_scale
	for i in range(amount):
		game_object_spawner.spawn(obj)
