class_name Board
extends Node2D

# Game
var game: GameConfig
var coordinate_scale: Vector2 = Vector2.ONE

var force_redraw: bool = false

var def_font: Font

# Children
var board_utilities: BoardUtilities

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

const REDRAW_PROPS: Array[String] = [
	"position", "rotation", "scale", "face_up"
]

@rpc("any_peer","call_remote","reliable")
func receive_property_updates(data: PackedByteArray) -> void:
	# Parse bytes received into dictionary
	var updates: Dictionary = bytes_to_var(data)
	# Update properties on pieces
	for p_name in updates.pieces.keys():
		for prop in updates.pieces[p_name].keys():
			set_gobject_property(p_name, true, prop, updates.pieces[p_name][prop], false)
	# Update properties on collections
	for c_name in updates.collections.keys():
		for prop in updates.collections[c_name].keys():
			set_gobject_property(c_name, false, prop, updates.collections[c_name][prop], false)

## Sets a gobject's property to a certain value
func set_gobject_property(n: String, piece: bool, prop: StringName, val: Variant, send_to_peer: bool = true) -> void:
	# Create the object if the object with the specified name does not exist
	if piece and not pieces.has(n):
		construct_piece({"name": n}, false)
	if not piece and not collections.has(n):
		construct_collection({"name": n}, false)
	# Assign our object and set the property
	var obj: Gobject
	if piece:
		obj = get_piece(n)
	else:
		obj = get_collection(n)
	obj.set(prop, val) # This is where we set the actual property
	# If we are to send to peer, add to our property updates reference
	if send_to_peer:
		if not n in property_updates.pieces:
			property_updates.pieces[n] = {}
		property_updates.pieces[n][prop] = val
	# Extra edits
	_extra_property_edits(obj, prop, val)

func _extra_property_edits(obj: Gobject, prop: StringName, val: Variant) -> void:
	if prop == "z_index":
		RenderingServer.canvas_item_set_z_index(obj.canvas_item, int(val * 100))
	if prop == "erased" and val == true:
		pieces.erase(obj.name)
	if prop in REDRAW_PROPS:
		set_obj_canvas_transform(obj)

func construct_piece(config: Dictionary, send_to_peer: bool = true) -> Piece:
	var piece: Piece = Piece.new()
	pieces[config.name] = piece
	piece.canvas_item = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(piece.canvas_item, get_canvas_item())
	for prop in config.keys():
		set_gobject_property(piece.name, true, prop, config[prop], send_to_peer)
	if "collection" in config:
		var new_inside: Dictionary = collections[config.collection].inside.duplicate(false)
		new_inside[config.name] = true
		set_gobject_property(config.collection, false, "inside", new_inside, send_to_peer)
	set_piece_texture(piece)
	set_gobject_property(piece.name, true, "z_index", max_z_index, send_to_peer)
	max_z_index += 0.001
	# Piece getting resource
	return piece

func set_piece_texture(piece: Piece) -> void:
	RenderingServer.canvas_item_add_texture_rect(
		piece.canvas_item, Rect2(-Vector2.ONE /2, Vector2.ONE),
		game.images[piece.image_up if piece.face_up else piece.image_down].get_rid()
		)

func set_collection_drawing(collection: Collection) -> void:
	RenderingServer.canvas_item_add_polygon(
		collection.canvas_item,
		collection.shape,
		PackedColorArray([Color.from_hsv(0.0, 1.0, 0.0, 0.4)])
	)

func set_obj_canvas_transform(obj: Gobject) -> void:
	RenderingServer.canvas_item_set_transform(obj.canvas_item, get_obj_transform(obj))

func construct_collection(config: Dictionary, send_to_peer: bool = true) -> Collection:
	var collection: Collection = Collection.new()
	collections[config.name] = collection
	collection.canvas_item = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(collection.canvas_item, get_canvas_item())
	for prop in config.keys():
		set_gobject_property(collection.name, false, prop, config[prop], send_to_peer)
	for obj in collection.inside.keys():
		var piece: Piece = get_piece(obj)
		if piece != null:
			board_utilities.remove_piece_from_collection(piece)
		set_gobject_property(obj, true, "collection", collection.name, send_to_peer)
	# Piece getting resource
	set_collection_drawing(collection)
	return collection

func _draw() -> void:
	draw_board_bg()
	for key in collections.keys():
		var collection: Collection = collections[key]
		draw_string(def_font,get_obj_extents(collection)[0], str(collection.inside.size()))
	force_redraw = false
		
## Draw the background specified
func draw_board_bg() -> void:
	if board_bg != "":
		draw_texture_rect(game.images[board_bg], border, false)
	draw_rect(border, Color.WHITE, false, Globals.OUTLINE_THICKNESS)

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

func obj_rect_overlaps_point(obj: Gobject, point: Vector2) -> bool:
	var rect: Rect2 = get_obj_rect_extents(obj)
	return rect.has_point(point)

func obj_overlaps_point(obj: Gobject, point: Vector2) -> bool:
	var shape: PackedVector2Array = get_obj_extents(obj)
	return Geometry2D.is_point_in_polygon(point, shape)

func obj_overlaps_polygon(obj: Gobject, rect: PackedVector2Array) -> bool:
	var shape: PackedVector2Array = get_obj_extents(obj)
	return not Geometry2D.intersect_polygons(shape, rect).is_empty()

func get_obj_rect_extents(obj: Gobject) -> Rect2:
	return get_obj_transform(obj) * get_obj_rect(obj)

func get_obj_rect(_obj: Gobject) -> Rect2:
	return Rect2(- Vector2.ONE / 2, Vector2.ONE)

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

# Draw order of objects

func get_sorted_pieces() -> Array[Piece]:
	var pcs: Array[Piece] = []
	pcs.assign(pieces.values())
	pcs.sort_custom(sort_by_draw_order)
	return pcs

func sort_by_draw_order(obj1: Piece, obj2: Piece) -> bool:
	return obj1.z_index < obj2.z_index

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

## Self explanatory
func clamp_camera() -> void:
	get_parent().camera_controller.camera.position = get_parent().camera_controller.camera.position.clamp(border.position, border.end)

## Updates objects position to their collections
func update_objects_position(collection: Collection):
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

@rpc("authority", "call_local", "unreliable")
func game_percent_loaded(pc: float) -> void:
	SignalManager.game_percent_loaded.emit(pc)

@rpc("authority", "call_local", "reliable")
func game_load_finished() -> void:
	SignalManager.game_load_finished.emit()

@rpc("authority", "call_local", "reliable")			
func game_load_started() -> void:
	SignalManager.game_load_started.emit()

####################
### Config stuff ###
####################

## Called when the board is initialized
func _ready() -> void:
	board_utilities = BoardUtilities.new(self) # New boardutilities
	def_font = ThemeDB.fallback_font
	SignalManager.game_load_started.emit()
	_init_board_props()
	_update_menu_bar()
	is_ready.rpc_id(1, multiplayer.get_unique_id())

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
	var x: float = 0
	for item in game.objects:
		await get_tree().create_timer(0.01).timeout
		game_percent_loaded.rpc(x / game.objects.size())
		_process_cnfg_obj(item)
		x += 1
	await get_tree().create_timer(0.01).timeout
	coordinate_scale = Vector2.ONE
	game_load_finished.rpc()

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
				construct_collection(obj, true)
			"piece":
				if not obj.has("name"):
					obj.name = unique_name("piece")
				construct_piece(obj, true)

func _on_send_data_timer_timeout() -> void:
	if not (property_updates.pieces.is_empty() and property_updates.collections.is_empty()):
		receive_property_updates.rpc(var_to_bytes(property_updates))
		property_updates = {"collections": {}, "pieces": {}}