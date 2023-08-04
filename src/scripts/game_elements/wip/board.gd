class_name Board
extends Node2D

# Game
var game: GameConfig
var coordinate_scale: Vector2 = Vector2.ONE

var def_font: Font

# Board properties
var board_bg: String = ""
var border: Rect2 = Rect2(0,0,0,0)
# Game objects
var pieces: Dictionary = {}
var collections: Dictionary = {}

var draw_order: PackedStringArray = PackedStringArray([])

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
	"state": -1,
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
		"state": -1,
		"face_up": config.face_up,
		"z": config.z
	}

var REFERENCE_COLLECTION: Dictionary = {
	# Collection name and type
	"name": "COLLECTION",
	"type": TYPE.COLLECTION,
	"state": -1,
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
		"state": -1,
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
func spawn_object(obj: Dictionary) -> Dictionary:
	match obj.type:
		TYPE.PIECE: return spawn_piece(obj)
		TYPE.COLLECTION: return spawn_collection(obj)
	return {}

## Inserts a piece into the pieces list
func spawn_piece(piece: Dictionary) -> Dictionary:
	var i: int = 0
	while pieces.has(str(piece.name,"_",i)):
		i += 1
	pieces[str(piece.name,"_",i)] = piece
	piece.name = str(piece.name,"_",i)
	# Add the piece to the draw order array
	draw_order.append(piece.name)
	return piece

## Inserts a collection into the collections list
func spawn_collection(collection: Dictionary) -> Dictionary:
	var i: int = 0
	while collections.has(str(collection.name,"_",i)):
		i += 1
	collections[str(collection.name,"_",i)] = collection
	collection.name = str(collection.name,"_",i)
	return collection

func _draw() -> void:
	draw_board_bg()
	for key in collections.keys():
		draw_collection(collections[key])
	for obj in draw_order:
		draw_piece(pieces[obj])
	for key in collections.keys():
		draw_string(def_font,get_obj_extents(collections[key])[0], str(collections[key].inside.size()))
		
## Draw the background specified
func draw_board_bg() -> void:
	if board_bg != "":
		draw_texture_rect(game.images[board_bg], border, false)
	
	draw_rect(border, Color.WHITE, false, Globals.OUTLINE_THICKNESS)

## Draws a game piece
func draw_piece(obj: Dictionary) -> void:
	var extents: PackedVector2Array = get_obj_extents(obj)
	draw_colored_polygon(extents, Color.WHITE,PackedVector2Array([Vector2(0,0), Vector2(0,1), Vector2(1,1), Vector2(1,0)]),
		game.images[obj.image_up if obj.face_up else obj.image_down]
		)
	draw_polyline(
		extents + PackedVector2Array([extents[0]]),
		Color.WHITE,
		Globals.OBJECT_HIGHLIGHT_BORDER
		)
	if obj.collection != "":
		var collection: Dictionary = get_collection(obj.collection)
		collection.scale.x = maxf(obj.scale.x, collection.scale.x)
		collection.scale.y = maxf(obj.scale.y, collection.scale.y)

## Draws a collection
func draw_collection(obj: Dictionary) -> void:
	var extents: PackedVector2Array = get_obj_extents(obj)
	draw_colored_polygon(
		extents,
		Color.from_hsv(0.0, 1.0, 0.0, 0.4)
		)
	obj.scale.x = obj.base_size.x
	obj.scale.y = obj.base_size.y

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

#################
### Utilities ###
#################

# Adding and removing from collections

## Adds a piece to the collection specified. Removes a piece from current collection if it exists
func add_piece_to_collection(piece: Dictionary, collection: Dictionary) -> void:
	if piece.collection != "": remove_piece_from_collection(piece)
	piece.collection = collection.name
	collection.inside.append(piece.name)

## Removes a piece from a collection, if it has any
func remove_piece_from_collection(piece: Dictionary) -> void:
	if piece.collection == "": return
	var c: Dictionary = get_collection(piece.collection)
	var index: int = c.inside.find(piece.name)
	if index != -1:
		c.inside.remove_at(index)
		if not c.permanent:
			if c.inside.size() == 1:
				remove_piece_from_collection(get_piece(c.inside[0]))
			elif c.inside.is_empty():
				# Essentially queue free
				collections.erase(c.name)
				print("Removing collection ", c.name)
	piece.collection = ""

# Draw order of objects

## Brings an object to the front
func move_object_to_top(piece: Dictionary) -> void:
	draw_order.remove_at(draw_order.find(piece.name))
	draw_order.push_back(piece.name)

## Brings an object to the back
func move_object_to_back(piece: Dictionary) -> void:
	draw_order.remove_at(draw_order.find(piece.name))
	draw_order.insert(0, piece.name)

## Flips an object
func flip_object(piece: Dictionary) -> void:
	piece.face_up = not piece.face_up

## Shuffles objects
func shuffle(pieces: Array) -> void:
	# TODO: Implement this
	pass

# Checking if player can select

## True if the current player can select this piece, false otherwise
func can_access_piece(piece: Dictionary) -> bool:
	if piece.collection != "":
		var collection = get_collection(piece.collection)
		return can_access_collection(collection)
	return true

## Returns true if the current player can access this collection, false otherwise
func can_access_collection(collection: Dictionary) -> bool:
	if collection.access_perms.size() <= Player.get_id():
		return true # Default to true if there's no access perms
	elif collection.access_perms[Player.get_id()] == false:
		return false
	return true

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
	def_font = ThemeDB.fallback_font
	coordinate_scale = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
	init_brd_prps()
	updt_mnu_bar()
	brd_objs_frm_cnfg()
	cll_fll_ins()
	coordinate_scale = Vector2.ONE

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
