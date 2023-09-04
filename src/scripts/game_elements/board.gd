class_name Board
extends Node2D

# Tabletop Game Loaded
var game: TabletopGame = null

var size: Vector2 = Vector2.ONE

var def_font: Font = null

# Children
@onready var board_player: BoardPlayer = $BoardPlayer
@onready var board_objects: Node2D = $BoardObjects
@onready var highlights: Node2D = $Highlights

# Board properties
var background: String = ""
var border: Rect2 = Rect2(0,0,0,0)

var counter: int = 0

func _draw() -> void:
	draw_board_bg()

## Draw the background specified
func draw_board_bg() -> void:
	if background != "":
		draw_texture_rect(game.include_images[background], border, false)
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

func clear_board() -> void:
	for obj in get_game_objects():
		obj.erase_self.rpc()

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

## Creates new game object on the board
func new_game_object(type, properties: Dictionary) -> GameObject:
	var c: GameObject = type.new()
	for prop in properties:
		c.set(prop, properties[prop])
	c.board = self
	add_child(c)
	return c

####################
### Config stuff ###
####################

## Called when the board is initialized
func _ready() -> void:
	board_player.board = self
	highlights.board = self
	
	get_viewport().set_physics_object_picking(true)
	get_viewport().set_physics_object_picking_sort(true)

	game.add_board(self)
	is_ready.rpc_id(1, multiplayer.get_unique_id())
	def_font = ThemeDB.fallback_font

@rpc("any_peer","call_local","reliable")
func is_ready(id: int) -> void:
	if multiplayer.is_server():
		ready_players.append(id)
		if ready_players.size() == multiplayer.get_peers().size() + 1:
			game.game_start()
			game_load_finished.rpc()

@rpc("authority", "call_local", "unreliable")
func game_percent_loaded(pc: float) -> void:
	SignalManager.game_percent_loaded.emit(pc)

@rpc("authority", "call_local", "reliable")
func game_load_finished() -> void:
	SignalManager.game_load_finished.emit(self)

@rpc("authority", "call_local", "reliable")			
func game_load_started() -> void:
	SignalManager.game_load_started.emit()
