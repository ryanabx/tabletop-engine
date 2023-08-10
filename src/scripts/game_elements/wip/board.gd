class_name Board
extends Node2D

# Game
var game: GameConfig
var coordinate_scale: Vector2 = Vector2.ONE

var force_redraw: bool = false

var def_font: Font

# Board properties
var board_bg: String = ""
var border: Rect2 = Rect2(0,0,0,0)
# Game objects
var pieces: Dictionary = {}
var collections: Dictionary = {}

var counter: int = 0

var max_z_index: float = 0.001
var min_z_index: float = -0.001

var property_updates: Dictionary = {"pieces": {}, "collections": {}}

signal gobject_created(obj: Gobject)

const INTERPOLATE_PROPS: Array[String] = [
	
]

const REDRAW_PROPS: Array[String] = [
	"position", "rotation", "scale", "face_up"
]

@rpc("any_peer","call_remote","reliable")
func receive_property_updates(data: PackedByteArray) -> void:
	var tween: Tween = null
	# Parse bytes received into dictionary
	var updates: Dictionary = bytes_to_var(data)
	# Update properties on pieces
	for p_name in updates.pieces.keys():
		if not pieces.has(p_name):
			add_piece(construct_piece({"name": p_name}))
		var piece: Piece = get_piece(p_name)
		if updates.pieces[p_name].has("erased") and updates.pieces[p_name]["erased"] == true:
			pieces.erase(p_name)
			continue
		for prop in updates.pieces[p_name].keys():
			if prop in REDRAW_PROPS:
				force_redraw = true
			if prop == "z_index":
				max_z_index = maxf(max_z_index, updates.pieces[p_name][prop] + 0.001)
				min_z_index = minf(min_z_index, updates.pieces[p_name][prop] - 0.001)
			if INTERPOLATE_PROPS.has(prop):
				if tween == null:
					tween = get_tree().create_tween().set_trans(Tween.TRANS_CIRC)
				tween.tween_property(piece, prop, updates.pieces[p_name][prop],0.1)
			else:
				piece.set(prop, updates.pieces[p_name][prop])
	# Update properties on collections
	for c_name in updates.collections.keys():
		if not collections.has(c_name):
			add_collection(construct_collection({"name": c_name}))
		if updates.collections[c_name].has("erased") and updates.collections[c_name]["erased"] == true:
			collections.erase(c_name)
			continue
		var collection: Collection = get_collection(c_name)
		for prop in updates.collections[c_name].keys():
			if prop in REDRAW_PROPS:
				force_redraw = true
			if prop == "z_index":
				max_z_index = maxf(max_z_index, updates.pieces[c_name][prop] + 0.001)
				min_z_index = minf(min_z_index, updates.pieces[c_name][prop] - 0.001)
			if INTERPOLATE_PROPS.has(prop):
				if tween == null:
					tween = get_tree().create_tween().set_trans(Tween.TRANS_CIRC)
				tween.tween_property(collection, prop, updates.collections[c_name][prop],0.1)
			else:
				collection.set(prop, updates.collections[c_name][prop])

## Sets a gobject's property to a certain value
func set_gobject_property(n: String, piece: bool, prop: StringName, val: Variant) -> void:
	if prop in REDRAW_PROPS:
		force_redraw = true
	if piece == true:
		if not pieces.has(n):
			add_piece(construct_piece({"name": n}))
		var obj: Piece = get_piece(n)
		obj.set(prop, val)
		if prop == "erased" and val == true:
			pieces.erase(n)
		if not n in property_updates.pieces:
			property_updates.pieces[n] = {}
		property_updates.pieces[n][prop] = val
	else:
		if not collections.has(n):
			add_collection(construct_collection({"name": n}))
		var obj: Collection = get_collection(n)
		obj.set(prop, val)
		if prop == "erased" and val == true:
			collections.erase(n)
		if not n in property_updates.collections:
			property_updates.collections[n] = {}
		property_updates.collections[n][prop] = val

func create_piece_bcast(config: Dictionary) -> Piece:
	var piece: Piece = Piece.new()
	piece.name = config.name
	add_piece(piece)
	for prop in config.keys():
		set_gobject_property(piece.name, true, prop, config[prop])
	if "collection" in config:
		var new_inside: Dictionary = collections[config.collection].inside.duplicate(false)
		new_inside[config.name] = true
		set_gobject_property(config.collection, false, "inside", new_inside)
	set_gobject_property(piece.name, true, "z_index", max_z_index)
	max_z_index += 0.001
	return piece

func construct_piece(config: Dictionary) -> Piece:
	var piece: Piece = Piece.new()
	for prop in config.keys():
		piece.set(prop, config[prop])
	if "collection" in config:
		if collections.has(config.collection):
			collections[config.collection].inside[config.name] = true
	piece.z_index = max_z_index
	max_z_index += 0.001
	return piece

func add_piece(piece: Piece) -> void:
	pieces[piece.name] = piece # Added object
	gobject_created.emit(piece)

func create_collection_bcast(config: Dictionary) -> Collection:
	var collection: Collection = Collection.new()
	collection.name = config.name
	add_collection(collection)
	for prop in config.keys():
		set_gobject_property(collection.name, false, prop, config[prop])
	for obj in collection.inside.keys():
		var piece: Piece = get_piece(obj)
		if piece != null:
			remove_piece_from_collection(piece)
		set_gobject_property(obj, true, "collection", collection.name)
	return collection

func construct_collection(config: Dictionary) -> Collection:
	var collection: Collection = Collection.new()
	for prop in config.keys():
		collection.set(prop, config[prop])
	
	for obj in get_pieces(collection.inside.keys()):
		if obj != null:
			obj.collection = collection.name
	# Add all currently made objects that reference this collection into the inside list
	for obj in pieces.values():
		if obj.collection == collection.name:
			collection.inside[obj.name] = true
	return collection

func add_collection(collection: Collection) -> void:
	collections[collection.name] = collection # Added object
	gobject_created.emit(collection)

func _draw() -> void:
	draw_board_bg()
	for key in collections.keys():
		var collection: Collection = collections[key]
		draw_collection(collection)
	for piece in get_sorted_pieces():
		# if piece.collection == "":
		draw_piece(piece)
	for key in collections.keys():
		var collection: Collection = collections[key]
		draw_string(def_font,get_obj_extents(collection)[0], str(collection.inside.size()))
	force_redraw = false
		
## Draw the background specified
func draw_board_bg() -> void:
	if board_bg != "":
		draw_texture_rect(game.images[board_bg], border, false)
	
	draw_rect(border, Color.WHITE, false, Globals.OUTLINE_THICKNESS)

## Draws a game piece
func draw_piece(obj: Piece) -> void:
	# var extents: PackedVector2Array = get_obj_extents(obj)
	draw_texture_rect(game.images[obj.image_up if obj.face_up else obj.image_down], Rect2(obj.position - obj.scale / 2, obj.scale), false)
	# draw_polyline(
	# 	extents + PackedVector2Array([extents[0]]),
	# 	Color.WHITE,
	# 	Globals.OBJECT_HIGHLIGHT_BORDER
	# 	)
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
	set_gobject_property(obj.name, false, "position", pos)
	for pc in obj.inside:
		var piece: Piece = get_piece(pc)
		if piece == null:
			continue
		set_gobject_property(piece.name, true, "position", pos)
		set_gobject_property(piece.name, true, "rotation", obj.rotation)

func move_piece(obj: Piece, pos: Vector2) -> void:
	set_gobject_property(obj.name, true, "position", pos)

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
	if piece.collection != "": remove_piece_from_collection(piece)
	set_gobject_property(piece.name, true, "collection", c_name)
	var collection = get_collection(c_name)
	if collection == null:
		return
	var new_inside: Dictionary = collection.inside.duplicate(false)
	new_inside[piece.name] = true
	set_gobject_property(collection.name, false, "inside", new_inside)
	set_gobject_property(piece.name, true, "position", collection.position)

## Removes a piece from a collection, if it has any
func remove_piece_from_collection(piece: Piece) -> void:
	if piece == null:
		return
	var c: Collection = get_collection(piece.collection)
	set_gobject_property(piece.name, true, "collection", "")
	if c == null:
		return
	var new_inside: Dictionary = c.inside.duplicate(false)
	new_inside.erase(piece.name)
	set_gobject_property(c.name, false, "inside", new_inside)
	if not c.permanent:
		if c.inside.size() == 1:
			remove_piece_from_collection(get_piece(c.inside.keys()[0]))
		elif c.inside.is_empty():
			# Essentially queue free
			set_gobject_property(c.name, false, "erased", true)

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
	set_gobject_property(piece.name, true, "z_index", max_z_index)
	max_z_index += 0.001

## Brings an object to the back
func move_object_to_back(piece: Piece) -> void:
	set_gobject_property(piece.name, true, "z_index", min_z_index)
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
	set_gobject_property(pc1.name, true, "position", contents.position)
	set_gobject_property(pc1.name, true, "rotation", contents.rotation)
	set_gobject_property(pc1.name, true, "z_index", contents.z_index)
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
	if force_redraw:
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
			coordinate_scale = Vector2(game.board.coordinate_scale.x, game.board.coordinate_scale.y)
			_init_board_objs()
			coordinate_scale = Vector2.ONE
			

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
		match obj.type:
			"collection":
				if "scale" in obj:
					obj.base_size = obj.scale
				if not obj.has("name"):
					obj.name = unique_name("collection")
				create_collection_bcast(obj)
			"piece":
				if not obj.has("name"):
					obj.name = unique_name("piece")
				create_piece_bcast(obj)


func _on_send_data_timer_timeout() -> void:
	if not (property_updates.pieces.is_empty() and property_updates.collections.is_empty()):
		receive_property_updates.rpc(var_to_bytes(property_updates))
		property_updates = {"collections": {}, "pieces": {}}
