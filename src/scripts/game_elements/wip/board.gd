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
# Property updates
var deltas: Dictionary = {"collections": {}, "pieces": {}}
var u_deltas: Dictionary = {"collections": {}, "pieces": {}}

var draw_order: PackedStringArray = PackedStringArray([])

## Game object
class Gobject extends Object:
	var position: Vector2 = Vector2.ZERO
	var rotation: float = 0.0
	var scale: Vector2 = Vector2.ONE
	var name: String = ""
	var shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)])
	var z_index: int = 0

## Game piece object
class Gpiece extends Gobject:
	var image_up: String = ""
	var image_down: String = ""
	var collection: Gcollection = null
	var face_up: bool = false

	func _init(
		_position: Vector2 = Vector2.ZERO,
		_rotation: float = 0.0,
		_scale: Vector2 = Vector2.ONE,
		_name: String = "",
		_shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)]),
		_z_index: int = 0,
		_image_up: String = "",
		_image_down: String = "",
		_collection: Gcollection = null,
		_face_up: bool = false
	) -> void:
		self.position = _position
		self.rotation = _rotation
		self.scale = _scale
		self.name = _name
		self.shape = _shape
		self.z_index = _z_index
		self.image_up = _image_up
		self.image_down = _image_down
		self.collection = _collection
		self.face_up = _face_up

## Collection type
class Gcollection extends Gobject:
	var base_size: Vector2 = Vector2.ONE
	var inside: Array[Gpiece] = []
	var view_perms: Array = []
	var access_perms: Array = []
	var permanent: bool = false
	var force_state: bool = false
	var type: Type = Type.STACK

	enum Type {STACK, HAND}

	func _init(
		_name: String = "",
		_position: Vector2 = Vector2.ZERO,
		_rotation: float = 0.0,
		_scale: Vector2 = Vector2.ONE,
		_shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)]),
		_z_index: int = 0,
		_base_size: Vector2 = Vector2.ONE,
		_inside: Array[Gpiece] = [],
		_view_perms: Array = [],
		_access_perms: Array = [],
		_permanent: bool = false,
		_force_state: bool = false,
		_type: Gcollection.Type = Gcollection.Type.STACK
	) -> void:
		self.position = _position
		self.rotation = _rotation
		self.scale = _scale
		self.name = _name
		self.shape = _shape
		self.z_index = _z_index
		self.base_size = _base_size
		self.inside = _inside
		self.view_perms = _view_perms
		self.access_perms = _access_perms
		self.permanent = _permanent
		self.force_state = _force_state
		self.type = _type

## Construct a new piece from a config
func construct_piece(config: Dictionary) -> Gpiece:
	var piece: Gpiece = Gpiece.new()
	piece.name = config.name if "name" in config else piece.name
	piece.position = Vector2(config.position.x, config.position.y) * coordinate_scale if "position" in config else piece.position
	piece.rotation = config.rotation if "rotation" in config else piece.rotation
	piece.scale = Vector2(config.scale.x, config.scale.y) * coordinate_scale if "scale" in config else piece.scale
	piece.image_up = config.image_up if "image_up" in config else piece.image_up
	piece.image_down = config.image_down if "image_down" in config else piece.image_down
	piece.shape = config.shape if "shape" in config else piece.shape
	piece.collection = Gcollection.new(config.collection) if "collection" in config else piece.collection
	piece.face_up = config.face_up if "face_up" in config else piece.face_up
	piece.z_index = config.z_index if "z" in config else piece.z_index

	return piece

## Construct a new collection from a config
func construct_collection(config: Dictionary) -> Gcollection:
	var collection: Gcollection = Gcollection.new()
	collection.name = config.name if "name" in config else collection.name
	collection.type = Gcollection.Type.HAND if "coll_type" in config and config.coll_type == "hand" else Gcollection.Type.STACK
	collection.position = Vector2(config.position.x, config.position.y) * coordinate_scale if "position" in config else collection.position
	collection.rotation = config.rotation if "rotation" in config else collection.rotation
	collection.scale = Vector2(config.scale.x, config.scale.y) * coordinate_scale if "scale" in config else collection.scale
	collection.base_size = Vector2(config.scale.x, config.scale.y) * coordinate_scale if "scale" in config else collection.base_size
	collection.z_index = config.z_index if "z" in config else collection.z_index
	collection.view_perms = config.view_perms if "view_perms" in config else collection.view_perms
	collection.access_perms = config.access_perms if "access_perms" in config else collection.access_perms
	collection.permanent = config.permanent if "permanent" in config else collection.permanent
	collection.force_state = config.force_state if "force_state" in config else collection.force_state
	collection.shape = config.shape if "shape" in config else collection.shape
	collection.inside = []
	return collection

@rpc("any_peer","call_remote","reliable")
func spawn_object(obj: Gobject) -> void:
	if obj is Gpiece and not pieces.has(obj.name):
		pieces[obj.name] = obj # Added object
	elif obj is Gcollection and not collections.has(obj.name):
		collections[obj.name] = obj # Added collection

## Makes the object's name exclusive
func make_name_exclusive(obj: Gobject) -> Gobject:
	var i: int = 0
	if obj is Gpiece:
		while pieces.has(str(obj.name,"_",i)):
			i += 1
	elif obj is Gcollection:
		while collections.has(str(obj.name,"_",i)):
			i += 1
	obj.name = str(obj.name,"_",i)
	# Add the piece to the draw order array
	if obj is Gpiece:
		draw_order.append(obj.name)
	return obj

func _draw() -> void:
	draw_board_bg()
	for key in collections.keys():
		var collection: Gcollection = collections[key]
		draw_collection(collection)
	for key in draw_order:
		var piece: Gpiece = pieces[key]
		draw_piece(piece)
	for key in collections.keys():
		var collection: Gcollection = collections[key]
		draw_string(def_font,get_obj_extents(collection)[0], str(collection.inside.size()))
		
## Draw the background specified
func draw_board_bg() -> void:
	if board_bg != "":
		draw_texture_rect(game.images[board_bg], border, false)
	
	draw_rect(border, Color.WHITE, false, Globals.OUTLINE_THICKNESS)

## Draws a game piece
func draw_piece(obj: Gpiece) -> void:
	var extents: PackedVector2Array = get_obj_extents(obj)
	draw_colored_polygon(extents, Color.WHITE,PackedVector2Array([Vector2(0,0), Vector2(0,1), Vector2(1,1), Vector2(1,0)]),
		game.images[obj.image_up if obj.face_up else obj.image_down]
		)
	draw_polyline(
		extents + PackedVector2Array([extents[0]]),
		Color.WHITE,
		Globals.OBJECT_HIGHLIGHT_BORDER
		)
	if obj.collection != null:
		var collection: Gcollection = obj.collection
		collection.scale.x = maxf(obj.scale.x, collection.scale.x)
		collection.scale.y = maxf(obj.scale.y, collection.scale.y)

## Draws a collection
func draw_collection(obj: Gcollection) -> void:
	var extents: PackedVector2Array = get_obj_extents(obj)
	draw_colored_polygon(
		extents,
		Color.from_hsv(0.0, 1.0, 0.0, 0.4)
		)
	obj.scale.x = obj.base_size.x
	obj.scale.y = obj.base_size.y

func get_piece(n: String) -> Gpiece:
	if n == "" or not pieces.has(n): return null
	return pieces[n]

func get_pieces(a: Array) -> Array[Gpiece]:
	var res: Array[Gpiece] = []
	for _a in a:
		res.append(get_piece(_a))
	return res

func get_collection(n: String) -> Gcollection:
	if n == "" or not collections.has(n): return null
	return collections[n]

func get_collections(a: Array) -> Array[Gcollection]:
	var res: Array[Gcollection] = []
	for _a in a:
		res.append(get_collection(_a))
	return res

func get_obj_extents(obj: Gobject) -> PackedVector2Array:
	return get_obj_transform(obj) * obj.shape
	
func get_obj_transform(obj: Gobject) -> Transform2D:
	return Transform2D(deg_to_rad(obj.rotation), obj.scale, 0.0, obj.position)

func obj_overlaps_point(obj: Gobject, point: Vector2) -> bool:
	var shape: PackedVector2Array = get_obj_extents(obj)
	return Geometry2D.is_point_in_polygon(point, shape)


########################
### Property updates ###
########################

## Updates properties on the remote
@rpc("any_peer","call_remote","reliable")
func update_deltas(delta: Dictionary) -> void:
	for key in delta.pieces.keys():
		pieces[key].merge(delta.pieces[key], true)
	for key in delta.collections.keys():
		if not collections.has(key):
			collections[key] = {}
		collections[key].merge(delta.collections[key], true)
	# print("Remote called update deltas reliable")

## Updates properties on the remote
@rpc("any_peer","call_remote","unreliable")
func update_u_deltas(u_delta: Dictionary) -> void:
	for key in u_delta.pieces.keys():
		pieces[key].merge(u_delta.pieces[key], true)
	for key in u_delta.collections.keys():
		collections[key].merge(u_delta.collections[key], true)
	# print("Remote called update deltas unreliable")

## Edits values inside a piece
func edit_piece_reliable(piece: Dictionary, changes: Dictionary) -> void:
	piece.merge(changes, true)
	if not deltas.pieces.has(piece.name): deltas.pieces[piece.name] = {}
	deltas.pieces[piece.name].merge(changes, true)

## Edits values inside a collection
func edit_collection_reliable(collection: Dictionary, changes: Dictionary) -> void:
	collection.merge(changes, true)
	if not deltas.collections.has(collection.name): deltas.collections[collection.name] = {}
	deltas.collections[collection.name].merge(changes, true)

## Edits values inside a piece
func edit_piece_unreliable(piece: Dictionary, changes: Dictionary) -> void:
	piece.merge(changes, true)
	if not u_deltas.pieces.has(piece.name): u_deltas.pieces[piece.name] = {}
	u_deltas.pieces[piece.name].merge(changes, true)

## Edits values inside a collection
func edit_collection_unreliable(collection: Dictionary, changes: Dictionary) -> void:
	collection.merge(changes, true)
	if not u_deltas.collections.has(collection.name): u_deltas.collections[collection.name] = {}
	u_deltas.collections[collection.name].merge(changes, true)

#################
### Utilities ###
#################

# Adding and removing from collections

## Adds a piece to the collection specified. Removes a piece from current collection if it exists
func add_piece_to_collection(piece: Board.Gpiece, collection: Board.Gcollection) -> void:
	if piece.collection != null: remove_piece_from_collection(piece)
	piece.collection = collection
	collection.inside.append(piece)


## Removes a piece from a collection, if it has any
func remove_piece_from_collection(piece: Gpiece) -> void:
	if piece.collection == null: return
	var c: Gcollection = piece.collection
	c.inside.erase(piece)
	if not c.permanent:
		if c.inside.size() == 1:
			remove_piece_from_collection(c.inside[0])
		elif c.inside.is_empty():
			# Essentially queue free
			erase_collection(c.name)
			print("Removing collection ", c.name)
	piece.collection = null

func erase_collection(collection_name: String) -> void:
	collections.erase(collection_name)

func erase_piece(piece_name: String) -> void:
	pieces.erase(piece_name)

# Draw order of objects

## Brings an object to the front
func move_object_to_top(piece: Gpiece) -> void:
	draw_order.remove_at(draw_order.find(piece.name))
	draw_order.push_back(piece.name)

## Brings an object to the back
func move_object_to_back(piece: Gpiece) -> void:
	draw_order.remove_at(draw_order.find(piece.name))
	draw_order.insert(0, piece.name)

## Flips an object
func flip_object(piece: Gpiece) -> void:
	piece.face_up = not piece.face_up

## Shuffles objects
func shuffle(pcs: Array[Gobject]) -> void:
	for obj in pcs:
		var index = draw_order.find(obj.name)
		draw_order.remove_at(index)

# Checking if player can select

## True if the current player can select this piece, false otherwise
func can_access_piece(piece: Gpiece) -> bool:
	if piece.collection != null:
		return can_access_collection(piece.collection)
	return true

## Returns true if the current player can access this collection, false otherwise
func can_access_collection(collection: Gcollection) -> bool:
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
	update_peers()

## Updates the peers if deltas exist
func update_peers() -> void:
	if not deltas.collections.is_empty() or not deltas.pieces.is_empty():
		rpc("update_deltas",deltas)
		# print("Updating deltas!")
		deltas = {"collections": {}, "pieces": {}}
	
	if not u_deltas.collections.is_empty() or not u_deltas.pieces.is_empty():
		rpc("update_u_deltas",u_deltas)
		# print("Updating u_deltas!")
		u_deltas = {"collections": {}, "pieces": {}}

## Self explanatory
func clamp_camera() -> void:
	get_parent().camera_controller.camera.position = get_parent().camera_controller.camera.position.clamp(border.position, border.end)

## Keeps positions of pieces in collection up-to-date
func update_positions_in_collection() -> void:
	for collection in collections.values():
		for piece in collection.inside:
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
	if is_multiplayer_authority():
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
			"collection": 
				var coll: Gcollection = construct_collection(obj)
				make_name_exclusive(coll)
				spawn_object(coll)
			"piece":
				var piece: Gpiece = construct_piece(obj)
				make_name_exclusive(piece)
				spawn_object(piece)

## Called on ready, makes sure that collections have all the pieces they are instantiated with
func cll_fll_ins() -> void:
	for piece in pieces.values():
		if piece.collection != null:
			var collection: Gcollection = collections[str(piece.collection.name)]
			piece.collection = collection
			collection.inside.append(piece)
