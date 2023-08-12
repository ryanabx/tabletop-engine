class_name Board
extends Node2D

@onready var piece_scene: PackedScene = preload("res://src/scenes/game_elements/gobjects/piece.tscn")
@onready var collection_scene: PackedScene = preload("res://src/scenes/game_elements/gobjects/collection.tscn")

# Game
var game: GameConfig

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

func get_gobject(n: String) -> Gobject:
	var o: Gobject = board_objects.get_node_or_null(n)
	return o

func get_game_objects() -> Array[Gobject]:
	var res: Array[Gobject] = []
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
@rpc("any_peer","call_local", "reliable")
func create_collection(data: PackedByteArray) -> void:
	var config: Dictionary = bytes_to_var(data)
	Collection.construct(self, config)

@rpc("any_peer","call_local", "reliable")
func create_piece(data: PackedByteArray) -> void:
	var config: Dictionary = bytes_to_var(data)
	Piece.construct(self, config)

@rpc("any_peer","call_local", "reliable")
func assign_authority(pid: int, objects: PackedStringArray):
	for obj in objects:
		get_gobject(obj).set_multiplayer_authority(pid)

func grab_authority_on_objs(objects: Array) -> void:
	var objs: PackedStringArray = PackedStringArray(objects.map(func(v: Gobject) -> String: return v.name))
	assign_authority.rpc(multiplayer.get_unique_id(), objs)

####################
### Config stuff ###
####################

## Called when the board is initialized
func _ready() -> void:
	board_player.board = self
	highlights.board = self

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
	SignalManager.game_load_finished.emit()

@rpc("authority", "call_local", "reliable")			
func game_load_started() -> void:
	SignalManager.game_load_started.emit()
