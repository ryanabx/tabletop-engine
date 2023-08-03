class_name Board
extends Node2D

# Game
var game: GameConfig
var coordinate_scale: Vector2 = Vector2.ONE

# Board properties
var board_bg: String = ""
var border: Rect2 = Rect2(0,0,0,0)
# Game objects
var pieces: Dictionary = {}
var collections: Dictionary = {}

## The state of a given piece
enum PIECE_STATE {
	IDLE,
	SELECTED,
	LOCKED
}

## The type of object contained
enum TYPE {
	PIECE,
	COLLECTION
}

var REFERENCE_PIECE: Dictionary = {
	# Piece name and type
	"name": "PIECE",
	"type": TYPE.PIECE,
	# Transform
	"position": Vector2.ZERO,
	"rotation": 0.0,
	"scale": Vector2.ONE,
	# Images
	"image_up": "",
	"image_down": "",
	# Shape, clockwise
	"shape": PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)]),
	# Name of collection attached to
	"collection": "",
	# Starting state
	"state": PIECE_STATE.IDLE,
	"face_up": false,
	"z": 0
}

func construct_piece(config: Dictionary) -> Dictionary:
	config.merge(REFERENCE_PIECE)
	return {
		# Piece name and type
		"name": config.name,
		"type": TYPE.PIECE,
		# Transform
		"position": Vector2(config.position.x, config.position.y) * coordinate_scale,
		"rotation": config.rotation,
		"scale": Vector2(config.scale.x, config.scale.y) * coordinate_scale,
		# Images
		"image_up": config.image_up,
		"image_down": config.image_down,
		# Shape, clockwise
		"shape": config.shape,
		# Name of collection attached to
		"collection": config.collection,
		# Starting state
		"state": PIECE_STATE.IDLE,
		"face_up": config.face_up,
		"z": config.z
	}

var REFERENCE_COLLECTION: Dictionary = {
	# Collection name and type
	"name": "COLLECTION",
	"type": TYPE.COLLECTION,
	# Transform
	"position": Vector2.ZERO,
	"rotation": 0.0,
	"scale": Vector2.ONE,
	# Constants
	"base_size": Vector2.ONE,
	"view_perms": [],
	"access_perms": [],
	"permanent": null,
	"force_state": null,
	# Shape, clockwise
	"shape": PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)]),
	# Inside
	"inside": PackedStringArray([]),
	# Collection type
	"coll_type": "stack",
	"z": 0
}

func construct_collection(config: Dictionary) -> Dictionary:
	config.merge(REFERENCE_COLLECTION)
	return {
		# Collection name and type
		"name": config.name,
		"type": TYPE.COLLECTION,
		# Transform
		"position": Vector2(config.position.x, config.position.y) * coordinate_scale,
		"rotation": config.rotation,
		"scale": Vector2(config.scale.x, config.scale.y) * coordinate_scale,
		# Constants
		"base_size": Vector2(config.scale.x, config.scale.y) * coordinate_scale,
		"view_perms": config.view_perms,
		"access_perms": config.access_perms,
		"permanent": config.permanent,
		"force_state": config.force_state,
		# Shape, clockwise
		"shape": config.shape,
		# Inside
		"inside": PackedStringArray([]),
		# Collection type
		"coll_type": config.coll_type,
		"z": config.z
	}

## Creates a new object on the board
func spawn_object(obj: Dictionary) -> void:
	match obj.type:
		TYPE.PIECE: spawn_piece(obj)
		TYPE.COLLECTION: spawn_collection(obj)

## Inserts a piece into the pieces list
func spawn_piece(piece: Dictionary) -> void:
	var i: int = 0
	while pieces.has(str(piece.name,"_",i)):
		i += 1
	pieces[str(piece.name,"_",i)] = piece
	piece.name = str(piece.name,"_",i)

## Inserts a collection into the collections list
func spawn_collection(collection: Dictionary) -> void:
	var i: int = 0
	while collections.has(str(collection.name,"_",i)):
		i += 1
	collections[str(collection.name,"_",i)] = collection
	collection.name = str(collection.name,"_",i)

func _draw() -> void:
	draw_board_bg()
	for obj in collections:
		draw_collection(collections[obj])
	for obj in pieces:
		draw_piece(pieces[obj])
		
## Draw the background specified
func draw_board_bg() -> void:
	if board_bg != "":
		draw_texture_rect(game.images[board_bg], border, false)
	
	draw_rect(border, Color.WHITE, false, Globals.OUTLINE_THICKNESS)

## Draws a game piece
func draw_piece(obj: Dictionary) -> void:
	draw_texture_rect(
		game.images[obj.image_up if obj.face_up else obj.image_down],
		Rect2(obj.position - obj.scale / 2, obj.scale),
		false
		)
	draw_polyline(
		get_obj_extents(obj),
		Color.BLACK,
		Globals.OBJECT_HIGHLIGHT_BORDER
		)

## Draws a collection
func draw_collection(obj: Dictionary) -> void:
	var extents = get_obj_extents(obj)
	draw_colored_polygon(
		extents,
		Color.from_hsv(0.0, 1.0, 0.0, 0.4)
		)

func get_piece(n: String) -> Dictionary:
	return pieces[n]

func get_collection(n: String) -> Dictionary:
	return collections[n]

func get_obj_extents(obj: Dictionary) -> PackedVector2Array:
	return get_obj_transform(obj) * obj.shape
	
func get_obj_transform(obj: Dictionary) -> Transform2D:
	return Transform2D(deg_to_rad(obj.rotation), obj.scale, 0.0, obj.position)

func obj_overlaps_point(obj: Dictionary, point: Vector2) -> bool:
	var shape: PackedVector2Array = get_obj_extents(obj)
	return Geometry2D.is_point_in_polygon(point, shape)

####################
### Main process ###
####################

func _process(_delta: float) -> void:
	clamp_camera()
	update_positions_in_collection()
	queue_redraw()

## Self explanatory
func clamp_camera() -> void:
	get_parent().camera_controller.camera.position = get_parent().camera_controller.camera.position.clamp(border.position, border.end)

## Keeps positions of pieces in collection up-to-date
func update_positions_in_collection() -> void:
	for key in collections.keys():
		var collection: Dictionary = collections[key]
		for pc in collection.inside:
			var piece: Dictionary = pieces[pc]
			piece.position = collection.position
			piece.rotation = collection.rotation

####################
### Config stuff ###
####################

## Called when the board is initialized
func _ready() -> void:
	coordinate_scale = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
	init_brd_prps()
	updt_mnu_bar()
	brd_objs_frm_cnfg()
	cll_fll_ins()

## Ran during startup, initializes the board's background and border
func init_brd_prps() -> void:
	if "border" in game.board:
		border = Rect2(
				(Vector2(game.board.border.position.x, game.board.border.position.y) - Vector2(game.board.border.scale.x, game.board.border.scale.y) / 2) * coordinate_scale,
				Vector2(game.board.border.scale.x, game.board.border.scale.y) * coordinate_scale
			)
	# Set up game bg
	if "background_image" in game.board and game.board.background_image != "":
		board_bg = game.board.background_image

## Ran during startup, notifies the menu bar that a new game is loaded
func updt_mnu_bar() -> void:
	get_parent().user_interface.menu_bar.new_game_loaded(game.player.max, game.actions)

## Ran during startup, initializes the board's objects
func brd_objs_frm_cnfg() -> void:
	for item in game.objects:
		prcs_cnfg_obj(item)

## Ran during startup, processes one object in the game config
func prcs_cnfg_obj(obj: Dictionary) -> void:
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
			var _o: Dictionary = mk_obj_dct(obj, repls)
			nw_cnf_obj(_o)
	else:
		nw_cnf_obj(obj)

## Ran during startup, makes an object dictionary from repls
func mk_obj_dct(original: Dictionary, repls: Dictionary) -> Dictionary:
	var obj: Dictionary = original.duplicate(true)
	for key in obj.keys():
		for repl in repls.keys():
			if typeof(obj[key]) == TYPE_STRING:
				obj[key] = obj[key].replacen(repl, repls[repl])
	return obj

## Ran during startup whenever a new config object is ready to be
## inserted into the board.
func nw_cnf_obj(obj: Dictionary) -> void:
	var amount: int = obj.repeat if "repeat" in obj else 1
	for i in range(amount):
		match obj.type:
			"collection": spawn_object(construct_collection(obj))
			"piece": spawn_object(construct_piece(obj))

## Called on ready, makes sure that collections have all the pieces they are instantiated with
func cll_fll_ins() -> void:
	for key in pieces.keys():
		var piece: Dictionary = pieces[key]
		if piece.collection != "":
			var collection: Dictionary = collections[piece.collection]
			collection.inside.append(key)
