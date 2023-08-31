class_name Board
extends Node2D

@onready var piece_scene: PackedScene = preload("res://src/scenes/game_elements/gobjects/piece.tscn")
@onready var collection_scene: PackedScene = preload("res://src/scenes/game_elements/gobjects/collection.tscn")

# Game
var game: GameConfig2

var def_font: Font

# Children
@onready var board_player: BoardPlayer = $BoardPlayer
@onready var board_objects: Node2D = $BoardObjects
@onready var highlights: Node2D = $Highlights

# Board properties
var board_bg: String = ""
var border: Rect2 = Rect2(0,0,0,0)

var counter: int = 0

func _draw() -> void:
	draw_board_bg()

## Draw the background specified
func draw_board_bg() -> void:
	if board_bg != "":
		draw_texture_rect(game.images[board_bg], border, false)
	draw_rect(border, Color.WHITE, false, Globals.OUTLINE_THICKNESS)

func get_piece(n: String) -> Piece:
	var pc: Piece = board_objects.get_node_or_null(n)
	return pc

func get_pieces(a: Array) -> Array[Piece]:
	var pcs: Array[Piece] = []
	for _a in a:
		var pc: Piece = get_piece(_a)
		if pc != null:
			pcs.append(pc)
	return pcs

func get_collection(n: String) -> Collection:
	var c: Collection = board_objects.get_node_or_null(n)
	return c

func get_collections(a: Array) -> Array[Collection]:
	var cs: Array[Collection] = []
	for _a in a:
		var c: Collection = get_collection(_a)
		if c != null:
			cs.append(c)
	return cs

func get_gobject(n: String) -> GameObject:
	var o: GameObject = board_objects.get_node_or_null(n)
	if o == null or o.get_parent() != self:
		return null
	return o

func get_game_objects() -> Array[GameObject]:
	var res: Array[GameObject] = []
	res.assign(board_objects.get_children())
	return res

func unique_name(s: String) -> String:
	var n: String = str(multiplayer.get_unique_id(),s,counter)
	counter += 1
	return n

####################
### Main process ###
####################

func _process(_delta: float) -> void:
	clamp_camera()
	queue_redraw()

## Self explanatory
func clamp_camera() -> void:
	get_parent().camera_controller.camera.position = get_parent().camera_controller.camera.position.clamp(border.position, border.end)

########################
### Multiplayer sync ###
########################

var ready_players: Array = []


#####################
### RPC functions ###
#####################
func create_collection(data: PackedByteArray) -> Collection:
	var config: Dictionary = bytes_to_var(data)
	var c: Collection = Collection.construct(self, config)
	_create_collection.rpc(data)
	print(c.name, " ",c.get_index())
	if c != null:
		c.auth = multiplayer.get_unique_id()
	return c

@rpc("any_peer","call_remote", "reliable")
func _create_collection(data: PackedByteArray) -> void:
	var config: Dictionary = bytes_to_var(data)
	Collection.construct(self, config)

func create_piece(data: PackedByteArray) -> Piece:
	var config: Dictionary = bytes_to_var(data)
	var p: Piece = Piece.construct(self, config)
	if p != null:
		_create_piece.rpc(data)
		print(p.name, " ", p.get_index())
		p.auth = multiplayer.get_unique_id()
	return p

@rpc("any_peer","call_remote", "reliable")
func _create_piece(data: PackedByteArray) -> void:
	var config: Dictionary = bytes_to_var(data)
	Piece.construct(self, config)

####################
### Config stuff ###
####################

## Called when the board is initialized
func _ready() -> void:
	board_player.board = self
	highlights.board = self

	get_viewport().set_physics_object_picking(true)
	get_viewport().set_physics_object_picking_sort(true)

	var coordinate_scale: Vector2 = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
	BoardSetup.setup_initial_board_state(self, coordinate_scale)
	is_ready.rpc_id(1, multiplayer.get_unique_id())
	def_font = ThemeDB.fallback_font

@rpc("any_peer","call_local","reliable")
func is_ready(id: int) -> void:
	if multiplayer.is_server():
		ready_players.append(id)
		if ready_players.size() == multiplayer.get_peers().size() + 1:
			var coordinate_scale: Vector2 = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
			BoardSetup.init_board_objs(self, coordinate_scale)

@rpc("authority", "call_local", "unreliable")
func game_percent_loaded(pc: float) -> void:
	SignalManager.game_percent_loaded.emit(pc)

@rpc("authority", "call_local", "reliable")
func game_load_finished() -> void:
	SignalManager.game_load_finished.emit(self)

@rpc("authority", "call_local", "reliable")			
func game_load_started() -> void:
	SignalManager.game_load_started.emit()

class BoardSetup:
	static func setup_initial_board_state(board: Board, coordinate_scale: Vector2) -> void:
		SignalManager.game_load_started.emit()
		_init_board_props(board, coordinate_scale)

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
					board.call_deferred("create_piece",var_to_bytes(obj))