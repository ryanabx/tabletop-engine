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
# Object deltas
var piece_properties_deferred: Dictionary = {}
var collection_properties_deferred: Dictionary = {}

var counter: int = 0

var max_z_index: float = 0.001
var min_z_index: float = -0.001

signal gobject_created(obj: Gobject)

const RELIABLE_PROPS: Array[String] = [
	"name",
	"shape",
	"collection",
	"image_up",
	"image_down",
	"face_up",
	"z_index",
	"base_size",
	"view_perms",
	"access_perms",
	"inside"
]

## Game object
class Gobject extends Object:
	var position: Vector2 = Vector2.ZERO
	var rotation: float = 0.0
	var scale: Vector2 = Vector2.ONE
	var name: String = ""
	var shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)])
	var z_index: float = 0.0
	var placeholder: bool = false

## Game piece object
class Gpiece extends Gobject:
	var image_up: String = ""
	var image_down: String = ""
	var collection: String = ""
	var face_up: bool = false

	func _init(
		_name: String = "",
		_z_index: float = 0.0,
		_position: Vector2 = Vector2.ZERO,
		_rotation: float = 0.0,
		_scale: Vector2 = Vector2.ONE,
		_shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)]),
		_image_up: String = "",
		_image_down: String = "",
		_collection: String = "",
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
	var inside: Array[String] = []
	var view_perms: Array = []
	var access_perms: Array = []
	var permanent: bool = false
	var force_state: bool = false
	var type: Type = Type.STACK

	enum Type {STACK, HAND}

	func _init(
		_name: String = "",
		_z_index: float = 0.0,
		_position: Vector2 = Vector2.ZERO,
		_rotation: float = 0.0,
		_scale: Vector2 = Vector2.ONE,
		_shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)]),
		_base_size: Vector2 = Vector2.ONE,
		_inside: Array[String] = [],
		_view_perms: Array = [],
		_access_perms: Array = [],
		_permanent: bool = false,
		_force_state: bool = false,
		_type: Gcollection.Type = Gcollection.Type.STACK,
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

@rpc("any_peer","call_local", "unreliable")
func _set_gobject_property_unreliable(data: PackedByteArray) -> void:
	var args: Dictionary = bytes_to_var(data)
	_set_gobject_property(args)

@rpc("any_peer","call_local", "reliable")
func _set_gobject_property_reliable(data: PackedByteArray) -> void:
	var args: Dictionary = bytes_to_var(data)
	_set_gobject_property(args)

func _set_gobject_property(args: Dictionary) -> void:
	if args.is_collection:
		if args.obj in collections:
			if args.val is Array:
				var val: Array[String] = []
				val.assign(args.val)
				collections[args.obj].set(args.prop, val)
			else:
				collections[args.obj].set(args.prop, args.val)
		else:
			if not args.obj in collection_properties_deferred:
				collection_properties_deferred[args.obj] = {}
			collection_properties_deferred[args.obj][args.prop] = args.val
	else:
		if args.obj in pieces:
			pieces[args.obj].set(args.prop, args.val)
		else:
			if not args.obj in piece_properties_deferred:
				piece_properties_deferred[args.obj] = {}
			piece_properties_deferred[args.obj][args.prop] = args.val
			

func set_gobject_property(obj: Gobject, prop: StringName, v: Variant) -> void:
	var val: Variant
	val = v
	
	var is_collection = obj is Gcollection
	
	var data: PackedByteArray = var_to_bytes({"obj": obj.name, "prop": prop, "val": val, "is_collection": is_collection})
	if prop in RELIABLE_PROPS:
		rpc("_set_gobject_property_reliable",data)
	else:
		rpc("_set_gobject_property_unreliable",data)

func modify_gobject_property(obj: Gobject, prop: StringName, v: Variant, append: bool = true) -> void:
	var val: Variant
	# Serializing objects
	if prop == "inside":
		val = v.name
	else:
		val = v
	
	var is_collection = obj is Gcollection
	
	var data: PackedByteArray = var_to_bytes({"obj": obj.name, "prop": prop, "val": val, "is_collection": is_collection, "append": append})
	rpc("_modify_gobject_property",data)

## Construct a new piece from a config
@rpc("any_peer","call_local","reliable")
func construct_piece_rpc(cfg: PackedByteArray) -> void:
	var config: Dictionary = bytes_to_var(cfg)
	var piece: Gpiece = construct_piece(config)
	add_piece(piece)

func construct_piece(config: Dictionary) -> Gpiece:
	var piece: Gpiece = Gpiece.new()
	for prop in config.keys():
		piece.set(prop, config[prop])
	if "collection" in config:
		if collections.has(config.collection) and not collections[config.collection].inside.has(config.name):
			collections[config.collection].inside.append(config.name)
	piece.z_index = max_z_index
	max_z_index += 0.001
	return piece

func add_piece(piece: Gpiece) -> void:
	pieces[piece.name] = piece # Added object
	if piece_properties_deferred.has(piece.name):
		for prop in piece_properties_deferred[piece.name].keys():
			piece.set(prop, piece_properties_deferred[piece.name][prop])
		piece_properties_deferred.erase(piece.name)
	gobject_created.emit(piece)

## Construct a new collection from a config
@rpc("any_peer","call_local","reliable")
func construct_collection_rpc(cfg: PackedByteArray) -> void:
	var config: Dictionary = bytes_to_var(cfg)
	var collection: Gcollection = construct_collection(config)
	add_collection(collection)

func construct_collection(config: Dictionary) -> Gcollection:
	var collection: Gcollection = Gcollection.new()
	for prop in config.keys():
		if prop == "inside":
			var val: Array[String] = []
			val.assign(config[prop])
			collection.set(prop, val)
		else:
			collection.set(prop, config[prop])
	print("Collection inside side: ",collection.inside.size())
	
	for obj in get_pieces(collection.inside):
		if obj != null:
			obj.collection = collection.name
			print("Set obj ",obj.name," collection to ",collection.name)
	# Add all currently made objects that reference this collection into the inside list
	collection.inside.append_array(pieces.values().filter(func(val: Gpiece) -> bool: return val.collection == collection.name and not collection.inside.has(val.name)).map(func(v: Gobject) -> String: return v.name))
	return collection

func add_collection(collection: Gcollection) -> void:
	collections[collection.name] = collection # Added object
	if collection_properties_deferred.has(collection.name):
		for prop in collection_properties_deferred[collection.name].keys():
			collection.set(prop, collection_properties_deferred[collection.name][prop])
		collection_properties_deferred.erase(collection.name)
	gobject_created.emit(collection)

func _draw() -> void:
	draw_board_bg()
	for key in collections.keys():
		var collection: Gcollection = collections[key]
		draw_collection(collection)
	for piece in get_sorted_pieces():
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
	var collection: Gcollection = get_collection(obj.collection)
	if collection == null:
		return
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
	var pcs: Array[Gpiece] = []
	pcs.assign(a.map(func(v: String) -> Gpiece: return pieces[v] if pieces.has(v) else null))
	return pcs

func get_collection(n: String) -> Gcollection:
	if n == "" or not collections.has(n): return null
	return collections[n]

func get_collections(a: Array) -> Array[Gcollection]:
	var clls: Array[Gcollection] = []
	clls.assign(a.map(func(v: String) -> Gcollection: return collections[v] if collections.has(v) else null))
	return clls

func get_obj_extents(obj: Gobject) -> PackedVector2Array:
	return get_obj_transform(obj) * obj.shape
	
func get_obj_transform(obj: Gobject) -> Transform2D:
	return Transform2D(deg_to_rad(obj.rotation), obj.scale, 0.0, obj.position)

func obj_overlaps_point(obj: Gobject, point: Vector2) -> bool:
	var shape: PackedVector2Array = get_obj_extents(obj)
	return Geometry2D.is_point_in_polygon(point, shape)

func obj_overlaps_polygon(obj: Gobject, rect: PackedVector2Array) -> bool:
	var shape: PackedVector2Array = get_obj_extents(obj)
	return not Geometry2D.intersect_polygons(shape, rect).is_empty()

func move_collection(obj: Gcollection, pos: Vector2) -> void:
	set_gobject_property(obj, "position", pos)
	for pc in obj.inside:
		var piece: Gpiece = get_piece(pc)
		if piece == null: continue
		set_gobject_property(piece, "position", pos)
		set_gobject_property(piece, "rotation", obj.rotation)

func move_piece(obj: Gpiece, pos: Vector2) -> void:
	set_gobject_property(obj, "position", pos)

func unique_name(s: String) -> String:
	var n: String = str(multiplayer.get_unique_id(),s,counter)
	counter += 1
	return n

#################
### Utilities ###
#################

# Adding and removing from collections

## Adds a piece to the collection specified. Removes a piece from current collection if it exists
func add_piece_to_collection(piece: Board.Gpiece, c_name: String) -> void:
	if piece.collection != "": remove_piece_from_collection(piece)
	set_gobject_property(piece, "collection", c_name)
	var collection = get_collection(c_name)
	var new_inside: Array[String] = []
	new_inside.assign(collection.inside)
	new_inside.append(piece.name)
	set_gobject_property(collection, "inside", new_inside)
	set_gobject_property(piece, "position", collection.position)

## Removes a piece from a collection, if it has any
func remove_piece_from_collection(piece: Gpiece) -> void:
	if piece == null:
		print("Piece was null")
		return
	var c: Gcollection = get_collection(piece.collection)
	set_gobject_property(piece, "collection", "")
	if c == null:
		print("Collection ",c," was null")
		return
	print("Setting new inside")
	var new_inside: Array[String] = []
	new_inside.assign(c.inside)
	new_inside.erase(piece.name)
	set_gobject_property(c, "inside", new_inside)
	if not c.permanent:
		if c.inside.size() == 1:
			remove_piece_from_collection(get_piece(c.inside[0]))
		elif c.inside.is_empty():
			# Essentially queue free
			rpc("erase_collection",c.name)

@rpc("any_peer","call_local","reliable")
func erase_collection(collection_name: String) -> void:
	"Erase collection"
	collections.erase(collection_name)

@rpc("any_peer","call_local","reliable")
func erase_piece(piece_name: String) -> void:
	pieces.erase(piece_name)

# Draw order of objects

func get_sorted_pieces() -> Array[Gpiece]:
	var pcs: Array[Gpiece] = []
	pcs.assign(pieces.values())
	pcs.sort_custom(sort_by_draw_order)
	return pcs

func sort_by_draw_order(obj1: Gpiece, obj2: Gpiece) -> bool:
	return obj1.z_index < obj2.z_index

## Brings an object to the front
func move_object_to_top(piece: Gpiece) -> void:
	piece.z_index = max_z_index
	max_z_index += 0.001

## Brings an object to the back
func move_object_to_back(piece: Gpiece) -> void:
	piece.z_index = min_z_index
	min_z_index -= 0.001

## Flips an object
func flip_object(piece: Gpiece) -> void:
	piece.face_up = not piece.face_up

## Shuffles objects
func shuffle(pcs: Array[Gpiece]) -> void:
	var pcs_shuffled: Array[Gpiece] = pcs.duplicate(false)
	pcs_shuffled.shuffle()
	for i in range(pcs.size()):
		var pc1: Gpiece = pcs[i]
		var pc2: Gpiece = pcs_shuffled[i]
		var contents1: Dictionary = {
			"position": pc1.position,
			"rotation": pc1.rotation,
			"z_index": pc1.z_index,
			"collection": pc1.collection
		}
		var contents2: Dictionary = {
			"position": pc2.position,
			"rotation": pc2.rotation,
			"z_index": pc2.z_index,
			"collection": pc2.collection
		}
		_swap(pc1, contents2)
		_swap(pc2, contents1)

func _swap(pc1: Gpiece, contents: Dictionary) -> void:
	set_gobject_property(pc1, "position", contents.position)
	set_gobject_property(pc1, "rotation", contents.rotation)
	set_gobject_property(pc1, "z_index", contents.z_index)
	if pc1.collection != contents.collection:
		add_piece_to_collection(pc1, collections[contents.collection])

func pieces_by_name(objects: Array[String]) -> Array[Gpiece]:
	var result: Array[Gpiece] = []
	result.assign(objects.map(func (value: String) -> Gpiece: return pieces[value]))
	return result

# Checking if player can select

## True if the current player can select this piece, false otherwise
func can_access_piece(piece: Gpiece) -> bool:
	if piece == null: return false
	var collection: Gcollection = get_collection(piece.collection)
	if collection != null:
		return can_access_collection(collection)
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
	queue_redraw()
	update_objects_position()

## Self explanatory
func clamp_camera() -> void:
	get_parent().camera_controller.camera.position = get_parent().camera_controller.camera.position.clamp(border.position, border.end)

## Updates objects position to their collections
func update_objects_position():
	for collection in collections.values():
		var pcs: Array[Gpiece] = get_pieces(collection.inside)
		for pc in pcs:
			if pc == null:
				continue
			pc.position = collection.position
			pc.rotation = collection.rotation


####################
### Config stuff ###
####################

## Called when the board is initialized
func _ready() -> void:
	def_font = ThemeDB.fallback_font
	coordinate_scale = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
	connect_signals()
	init_brd_prps()
	updt_mnu_bar()
	if is_multiplayer_authority():
		brd_objs_frm_cnfg()
	coordinate_scale = Vector2.ONE

func connect_signals() -> void:
	SignalManager.shuffle_selection.connect(shuffle)

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
func nw_cnf_obj(o: Dictionary) -> void:
	var amount: int = o.repeat if "repeat" in o else 1
	for i in range(amount):
		var obj: Dictionary = o.duplicate(true)
		if "position" in obj:
			obj.position = Vector2(obj.position.x * coordinate_scale.x, obj.position.y * coordinate_scale.y)
		if "scale" in obj:
			obj.scale = Vector2(obj.scale.x * coordinate_scale.x, obj.scale.y * coordinate_scale.y)
		print(coordinate_scale)
		match obj.type:
			"collection":
				if "scale" in obj:
					obj.base_size = obj.scale
				if not obj.has("name"):
					obj.name = unique_name("collection")
				rpc("construct_collection_rpc",(var_to_bytes(obj)))
			"piece":
				if not obj.has("name"):
					obj.name = unique_name("piece")
				rpc("construct_piece_rpc",(var_to_bytes(obj)))