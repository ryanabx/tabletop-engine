class_name Board
extends Node2D

# Tabletop Game Loaded
var game: TabletopGame = null

var size: Vector2 = Vector2.ONE

var def_font: Font = null

enum GameObjectType {
	PIECE,
	COLLECTION,
	MAX
}

const GAME_OBJECT_TYPE_STRING = [
	"piece", "collection", "max"
]

# Children
@onready var board_player: BoardPlayer = $BoardPlayer
@onready var board_objects: Node2D = $BoardObjects
@onready var highlights: Node2D = $Highlights

var background_sprite: Sprite2D

# Board properties
var background: String = "":
	set(val):
		background = val
		background_sprite.set_texture(game.include_images[background])
		background_sprite.scale = border.size / background_sprite.texture.get_size()
	get:
		return background

var border: Rect2 = Rect2(0,0,0,0)

var counter: int = 0

func _draw() -> void:
	draw_board_bg()

## Draw the background specified
func draw_board_bg() -> void:
	draw_rect(border, Color.WHITE, false, Globals.OUTLINE_THICKNESS)

func get_piece(n: String) -> Piece:
	var pc: Piece = board_objects.get_node_or_null(n)
	return pc

func get_pieces(a: Array) -> Array[Piece]:
	var pcs: Array[Piece] = []
	for _a: String in a:
		var pc: Piece = get_piece(_a)
		if pc != null:
			pcs.append(pc)
	return pcs

func get_collection(n: String) -> Collection:
	var c: Collection = board_objects.get_node_or_null(n)
	return c

func get_collections(a: Array) -> Array[Collection]:
	var cs: Array[Collection] = []
	for _a: String in a:
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
	for obj: GameObject in get_game_objects():
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
	get_parent().camera_controller.offset = get_parent().camera_controller.offset.clamp(border.position, border.end)

########################
### Multiplayer sync ###
########################

var ready_players: Array = []

#####################
### RPC functions ###
#####################

## Creates new game object on the board
func new_game_object(type: GameObjectType, properties: Dictionary) -> GameObject:
	var c: GameObject
	match type:
		GameObjectType.PIECE:
			c = Piece.new()
		GameObjectType.COLLECTION:
			c = Collection.new()
		GameObjectType.MAX:
			print("Can't instantiate type MAX")
			return
	c.board = self
	for prop: String in properties:
		c.set(prop, properties[prop])
	board_objects.add_child(c)
	# RPC
	_new_game_object_rpc.rpc(type, properties)
	return c

@rpc("any_peer", "call_remote", "reliable")
func _new_game_object_rpc(type: GameObjectType, properties: Dictionary) -> void:
	var c: GameObject
	match type:
		GameObjectType.PIECE:
			c = Piece.new()
		GameObjectType.COLLECTION:
			c = Collection.new()
		GameObjectType.MAX:
			print("Can't instantiate type MAX")
			return
	
	c.board = self
	for prop: String in properties:
		c.set(prop, properties[prop])
	board_objects.add_child(c)
	return

@rpc("any_peer", "call_remote", "reliable")
func _new_serialized_game_object_rpc(obj: Dictionary) -> void:
	var game_object: GameObject = dict_to_inst(obj)
	board_objects.add_child(game_object)

####################
### Config stuff ###
####################

## Called when the board is initialized
func _ready() -> void:
	board_player.board = self
	highlights.board = self

	background_sprite = Sprite2D.new()
	background_sprite.z_index = -10
	add_child(background_sprite)
	
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


func _on_sync_timer_timeout() -> void:
	SignalManager.property_sync.emit()
