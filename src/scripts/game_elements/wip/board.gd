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


func set_gobject_property(obj: Gobject, prop: StringName, val: Variant) -> void:
	var data: PackedByteArray = var_to_bytes({
		"obj": obj.name,
		"prop": prop,
		"val": val,
		"is_collection": obj is Collection
	})
	if prop in RELIABLE_PROPS:
		_set_gobject_property_reliable.rpc(data)
	else:
		_set_gobject_property_unreliable.rpc(data)

@rpc("any_peer","call_local", "unreliable")
func _set_gobject_property_unreliable(data: PackedByteArray) -> void:
	var args: Dictionary = bytes_to_var(data)
	# print("_set_gobject_property_unreliable: obj:", args.obj, ",prop:",args.prop,",val:",args.val)
	_set_gobject_property(args)

@rpc("any_peer","call_local", "reliable")
func _set_gobject_property_reliable(data: PackedByteArray) -> void:
	var args: Dictionary = bytes_to_var(data)
	# print("_set_gobject_property_reliable: obj:", args.obj, ",prop:",args.prop,",val:",args.val)
	_set_gobject_property(args)

func _set_gobject_property(args: Dictionary) -> void:
	if args.is_collection:
		if not args.obj in collections:
			add_collection(
				construct_collection({
					"name": args.obj
				})
			)
		if args.val is Array and args.prop == "inside":
			var val: Array[String] = []
			val.assign(args.val)
			collections[args.obj].set(args.prop, val)
		else:
			collections[args.obj].set(args.prop, args.val)
	else:
		if not args.obj in pieces:
			add_piece(
				construct_piece({
					"name": args.obj
				})
			)
		pieces[args.obj].set(args.prop, args.val)

@rpc("any_peer","call_remote","reliable")
func requested_all_information() -> void:
	if not is_multiplayer_authority():
		return
	var data: Dictionary = {
		"pieces": pieces,
		"collections": collections
	}
	full_sync_state.rpc(var_to_bytes_with_objects(data))

@rpc("authority", "call_remote", "reliable")
func full_sync_state(dt: PackedByteArray) -> void:
	var data: Dictionary = bytes_to_var_with_objects(dt)
	pieces = data.pieces
	collections = data.collections


## Construct a new piece from a config
@rpc("any_peer","call_local","reliable")
func construct_piece_rpc(cfg: PackedByteArray) -> void:
	print("Construct piece")
	var config: Dictionary = bytes_to_var(cfg)
	var piece: Piece = construct_piece(config)
	add_piece(piece)

func construct_piece(config: Dictionary) -> Piece:
	var piece: Piece = Piece.new()
	for prop in config.keys():
		piece.set(prop, config[prop])
	if "collection" in config:
		if collections.has(config.collection) and not collections[config.collection].inside.has(config.name):
			collections[config.collection].inside[config.name] = true
	piece.z_index = max_z_index
	max_z_index += 0.001
	return piece

func add_piece(piece: Piece) -> void:
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
	var collection: Collection = construct_collection(config)
	add_collection(collection)

func construct_collection(config: Dictionary) -> Collection:
	var collection: Collection = Collection.new()
	for prop in config.keys():
		collection.set(prop, config[prop])
	
	for obj in get_pieces(collection.inside.keys()):
		if obj != null:
			obj.collection = collection.name
			print("Set obj ",obj.name," collection to ",collection.name)
	# Add all currently made objects that reference this collection into the inside list
	for obj in pieces.values():
		if obj.collection == collection.name:
			collection.inside[obj.name] = true
	return collection

func add_collection(collection: Collection) -> void:
	collections[collection.name] = collection # Added object
	if collection_properties_deferred.has(collection.name):
		for prop in collection_properties_deferred[collection.name].keys():
			collection.set(prop, collection_properties_deferred[collection.name][prop])
		collection_properties_deferred.erase(collection.name)
	gobject_created.emit(collection)

func _draw() -> void:
	draw_board_bg()
	for key in collections.keys():
		var collection: Collection = collections[key]
		draw_collection(collection)
	for piece in get_sorted_pieces():
		draw_piece(piece)
	for key in collections.keys():
		var collection: Collection = collections[key]
		draw_string(def_font,get_obj_extents(collection)[0], str(collection.inside.size()))
		
## Draw the background specified
func draw_board_bg() -> void:
	if board_bg != "":
		draw_texture_rect(game.images[board_bg], border, false)
	
	draw_rect(border, Color.WHITE, false, Globals.OUTLINE_THICKNESS)

## Draws a game piece
func draw_piece(obj: Piece) -> void:
	var extents: PackedVector2Array = get_obj_extents(obj)
	draw_colored_polygon(extents, Color.WHITE,PackedVector2Array([Vector2(0,0), Vector2(0,1), Vector2(1,1), Vector2(1,0)]),
		game.images[obj.image_up if obj.face_up else obj.image_down]
		)
	draw_polyline(
		extents + PackedVector2Array([extents[0]]),
		Color.WHITE,
		Globals.OBJECT_HIGHLIGHT_BORDER
		)
	var collection: Collection = get_collection(obj.collection)
	if collection == null:
		return
	collection.scale.x = maxf(obj.scale.x, collection.scale.x)
	collection.scale.y = maxf(obj.scale.y, collection.scale.y)

## Draws a collection
func draw_collection(obj: Collection) -> void:
	var extents: PackedVector2Array = get_obj_extents(obj)
	draw_colored_polygon(
		extents,
		Color.from_hsv(0.0, 1.0, 0.0, 0.4)
		)
	obj.scale.x = obj.base_size.x
	obj.scale.y = obj.base_size.y

func get_piece(n: String) -> Piece:
	if n == "" or not pieces.has(n): return null
	return pieces[n]

func get_pieces(a: Array) -> Array[Piece]:
	var pcs: Array[Piece] = []
	pcs.assign(a.map(func(v: String) -> Piece: return pieces[v] if pieces.has(v) else null))
	return pcs

func get_collection(n: String) -> Collection:
	if n == "" or not collections.has(n): return null
	return collections[n]

func get_collections(a: Array) -> Array[Collection]:
	var clls: Array[Collection] = []
	clls.assign(a.map(func(v: String) -> Collection: return collections[v] if collections.has(v) else null))
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

func move_collection(obj: Collection, pos: Vector2) -> void:
	set_gobject_property(obj, "position", pos)
	for pc in obj.inside:
		var piece: Piece = get_piece(pc)
		if piece == null: continue
		set_gobject_property(piece, "position", pos)
		set_gobject_property(piece, "rotation", obj.rotation)

func move_piece(obj: Piece, pos: Vector2) -> void:
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
func add_piece_to_collection(piece: Piece, c_name: String) -> void:
	print("add piece to collection")
	if piece.collection != "": remove_piece_from_collection(piece)
	set_gobject_property(piece, "collection", c_name)
	var collection = get_collection(c_name)
	if collection == null:
		print("Collection cannot be found when adding piece")
		return
	var new_inside: Dictionary = collection.inside.duplicate(false)
	new_inside[piece.name] = true
	set_gobject_property(collection, "inside", new_inside)
	set_gobject_property(piece, "position", collection.position)

## Removes a piece from a collection, if it has any
func remove_piece_from_collection(piece: Piece) -> void:
	if piece == null:
		print("Piece was null")
		return
	var c: Collection = get_collection(piece.collection)
	set_gobject_property(piece, "collection", "")
	if c == null:
		print("Collection ",c," was null")
		return
	print("Setting new inside")
	var new_inside: Dictionary = c.inside.duplicate(false)
	new_inside.erase(piece.name)
	set_gobject_property(c, "inside", new_inside)
	if not c.permanent:
		if c.inside.size() == 1:
			remove_piece_from_collection(get_piece(c.inside.keys()[0]))
		elif c.inside.is_empty():
			# Essentially queue free
			erase_collection.rpc(c.name)

@rpc("any_peer","call_local","reliable")
func erase_collection(collection_name: String) -> void:
	"Erase collection"
	collections.erase(collection_name)

@rpc("any_peer","call_local","reliable")
func erase_piece(piece_name: String) -> void:
	pieces.erase(piece_name)

# Draw order of objects

func get_sorted_pieces() -> Array[Piece]:
	var pcs: Array[Piece] = []
	pcs.assign(pieces.values())
	pcs.sort_custom(sort_by_draw_order)
	return pcs

func sort_by_draw_order(obj1: Piece, obj2: Piece) -> bool:
	return obj1.z_index < obj2.z_index

## Brings an object to the front
func move_object_to_top(piece: Piece) -> void:
	piece.z_index = max_z_index
	max_z_index += 0.001

## Brings an object to the back
func move_object_to_back(piece: Piece) -> void:
	piece.z_index = min_z_index
	min_z_index -= 0.001

## Flips an object
func flip_object(piece: Piece) -> void:
	piece.face_up = not piece.face_up

## Shuffles objects
func shuffle(pcs: Array[Piece]) -> void:
	var pcs_shuffled: Array[Piece] = pcs.duplicate(false)
	pcs_shuffled.shuffle()
	for i in range(pcs.size()):
		var pc1: Piece = pcs[i]
		var pc2: Piece = pcs_shuffled[i]
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

func _swap(pc1: Piece, contents: Dictionary) -> void:
	set_gobject_property(pc1, "position", contents.position)
	set_gobject_property(pc1, "rotation", contents.rotation)
	set_gobject_property(pc1, "z_index", contents.z_index)
	if pc1.collection != contents.collection:
		add_piece_to_collection(pc1, collections[contents.collection])

func pieces_by_name(objects: Array[String]) -> Array[Piece]:
	var result: Array[Piece] = []
	result.assign(objects.map(func (value: String) -> Piece: return pieces[value]))
	return result

# Checking if player can select

## True if the current player can select this piece, false otherwise
func can_access_piece(piece: Piece) -> bool:
	if piece == null: return false
	var collection: Collection = get_collection(piece.collection)
	if collection != null:
		return can_access_collection(collection)
	return true

## Returns true if the current player can access this collection, false otherwise
func can_access_collection(collection: Collection) -> bool:
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
		if collection == null: continue
		var pcs: Array[Piece] = get_pieces(collection.inside.keys())
		for pc in pcs:
			if pc == null:
				continue
			pc.position = collection.position
			pc.rotation = collection.rotation


########################
### Multiplayer sync ###
########################

var ready_players: Array = []

@rpc("any_peer","call_local","reliable")
func is_ready(id: int) -> void:
	if multiplayer.is_server():
		ready_players.append(id)
		if ready_players.size() == multiplayer.get_peers().size() + 1:
			print("Size of ", ready_players, " is equal to ",multiplayer.get_peers())
			coordinate_scale = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
			_init_board_objs()
			coordinate_scale = Vector2.ONE
			print("Made board objs!")
			

####################
### Config stuff ###
####################

## Called when the board is initialized
func _ready() -> void:
	def_font = ThemeDB.fallback_font
	coordinate_scale = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
	connect_signals()
	_init_board_props()
	_update_menu_bar()
	coordinate_scale = Vector2.ONE
	is_ready.rpc_id(1, multiplayer.get_unique_id())
	
func connect_signals() -> void:
	SignalManager.shuffle_selection.connect(shuffle)

## Ran during startup, initializes the board's background and border
func _init_board_props() -> void:
	if "border" in game.board:
		border = Rect2(
				(Vector2(game.board.border.position.x, game.board.border.position.y) - Vector2(game.board.border.scale.x, game.board.border.scale.y) / 2) * coordinate_scale,
				Vector2(game.board.border.scale.x, game.board.border.scale.y) * coordinate_scale
			)
	# Set up game bg
	if "background_image" in game.board and game.board.background_image != "":
		board_bg = game.board.background_image

## Ran during startup, notifies the menu bar that a new game is loaded
func _update_menu_bar() -> void:
	get_parent().user_interface.menu_bar.new_game_loaded(game.player.max, game.actions)

## Ran during startup, initializes the board's objects
func _init_board_objs() -> void:
	for item in game.objects:
		_process_cnfg_obj(item)

## Ran during startup, processes one object in the game config
func _process_cnfg_obj(obj: Dictionary) -> void:
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
			var _o: Dictionary = _make_obj_dict(obj, repls)
			_new_conf_obj(_o)
	else:
		_new_conf_obj(obj)

## Ran during startup, makes an object dictionary from repls
func _make_obj_dict(original: Dictionary, repls: Dictionary) -> Dictionary:
	var obj: Dictionary = original.duplicate(true)
	for key in obj.keys():
		for repl in repls.keys():
			if typeof(obj[key]) == TYPE_STRING:
				obj[key] = obj[key].replacen(repl, repls[repl])
	return obj

## Ran during startup whenever a new config object is ready to be
## inserted into the board.
func _new_conf_obj(o: Dictionary) -> void:
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
				construct_collection_rpc.rpc(var_to_bytes(obj))
			"piece":
				if not obj.has("name"):
					obj.name = unique_name("piece")
				construct_piece_rpc.rpc(var_to_bytes(obj))
