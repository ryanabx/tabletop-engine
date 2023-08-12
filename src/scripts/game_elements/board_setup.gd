class_name BoardSetup
extends RefCounted

static func setup_initial_board_state(board: Board, coordinate_scale: Vector2) -> void:
	SignalManager.game_load_started.emit()
	_init_board_props(board, coordinate_scale)
	_update_menu_bar(board)

## Ran during startup, initializes the board's background and border
static func _init_board_props(board: Board, coordinate_scale: Vector2) -> void:
	if "border" in board.game.board:
		board.border = Rect2(
				(Vector2(board.game.board.border.position.x, board.game.board.border.position.y) - Vector2(board.game.board.border.scale.x, board.game.board.border.scale.y) / 2) * coordinate_scale,
				Vector2(board.game.board.border.scale.x, board.game.board.border.scale.y) * coordinate_scale
			)
	# Set up game bg
	if "background_image" in board.game.board and board.game.board.background_image != "":
		board.board_bg = board.game.board.background_image

## Ran during startup, notifies the menu bar that a new game is loaded
static func _update_menu_bar(board: Board) -> void:
	board.get_parent().user_interface.menu_bar.new_game_loaded(board.game.player.max, board.game.actions)

## Ran during startup, initializes the board's objects
static func init_board_objs(board: Board, coordinate_scale: Vector2) -> void:
	var x: float = 0
	for item in board.game.objects:
		await board.get_tree().create_timer(0.01).timeout
		board.game_percent_loaded.rpc(x / board.game.objects.size())
		_process_cnfg_obj(item, board, coordinate_scale)
		x += 1
	await board.get_tree().create_timer(0.01).timeout
	board.game_load_finished.rpc()

## Ran during startup, processes one object in the game config
static func _process_cnfg_obj(obj: Dictionary, board: Board, coordinate_scale: Vector2) -> void:
	# Use templates if they exist
	if "template" in obj:
		obj.merge(board.game.templates[obj.template])
	
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
			var _o: Dictionary = _make_obj_dict(obj, repls)
			_new_conf_obj(_o, board, coordinate_scale)
	else:
		_new_conf_obj(obj, board, coordinate_scale)

## Ran during startup, makes an object dictionary from repls
static func _make_obj_dict(original: Dictionary, repls: Dictionary) -> Dictionary:
	var obj: Dictionary = original.duplicate(true)
	for key in obj.keys():
		for repl in repls.keys():
			if typeof(obj[key]) == TYPE_STRING:
				obj[key] = obj[key].replacen(repl, repls[repl])
	return obj

## Ran during startup whenever a new config object is ready to be
## inserted into the board.
static func _new_conf_obj(o: Dictionary, board: Board, coordinate_scale: Vector2) -> void:
	var amount: int = o.repeat if "repeat" in o else 1
	for i in range(amount):
		var obj: Dictionary = o.duplicate(true)
		if "position" in obj:
			obj.position = Vector2(obj.position.x * coordinate_scale.x, obj.position.y * coordinate_scale.y)
		if "gobject_scale" in obj:
			obj.gobject_scale = Vector2(obj.gobject_scale.x * coordinate_scale.x, obj.gobject_scale.y * coordinate_scale.y)
		match obj.type:
			"collection":
				if "gobject_scale" in obj:
					obj.base_size = obj.gobject_scale
				if not obj.has("name"):
					obj.name = board.unique_name("collection")
				# print("Constructing collection ", obj.name)
				board.create_collection(var_to_bytes(obj))
			"piece":
				if not obj.has("name"):
					obj.name = board.unique_name("piece")
				# print("Constructing piece ",obj.name)
				board.create_piece(var_to_bytes(obj))