class_name Piece
extends Gobject

var image_up: String = ""
var image_down: String = ""
var collection: String = ""
var face_up: bool = false

var grab_offset: Vector2 = Vector2.ZERO

@onready var sprite_down: Sprite2D = $Down
@onready var sprite_up: Sprite2D = $Up

@onready var collision_polygon: CollisionPolygon2D = $Area2D/CollisionPolygon2D
@onready var area2d: Area2D = $Area2D

var selectable: bool = false


## Moves this object to the top of the draw order
@rpc("any_peer","call_local", "reliable")
func move_self_to_top() -> void:
	get_parent().move_child(self, -1)

## Moves this object to the back of the draw order
@rpc("any_peer","call_local", "reliable")
func move_self_to_back() -> void:
	get_parent().move_child(self, 0)

@rpc("any_peer","call_local", "reliable")
func move_to_index(index: int) -> void:
	get_parent().move_child(self, index)

func _ready() -> void:
	_refresh_image()
	collision_polygon.polygon = get_gobject_transform() * self.shape

func _process(_delta: float) -> void:
	update_position()

func update_position() -> void:
	if selected:
		position = (board.get_local_mouse_position() - grab_offset).clamp(board.border.position, board.border.end)
		if collection != "":
			get_collection().position = position

func get_collection() -> Collection:
	if collection == "":
		return null
	return board.get_collection(collection)

func update_position_in_collection() -> void:
	if collection != "":
		var coll: Collection = self.board.get_collection(collection)
		if coll != null:
			position = coll.position
			rotation = coll.rotation
			if coll.force_state != null and face_up != coll.force_state:
				set_face(coll.force_state)

## Sets the object's face
func set_face(_face_up: bool) -> void:
	face_up = _face_up
	_refresh_image()

## Flips the object's face
func flip() -> void:
	face_up = not face_up
	_refresh_image()

## Adds this piece to a collection with the name c_name
func add_to_collection(coll: Collection) -> void:
	if coll != null:
		remove_from_collection()
		coll.add_piece(self)
		collection = coll.name
		coll.gobject_scale.x = maxf(gobject_scale.x, coll.gobject_scale.x)
		coll.gobject_scale.y = maxf(gobject_scale.y, coll.gobject_scale.y)
		update_position_in_collection()

## Removes the piece from its collection, if any  
func remove_from_collection() -> void:
	if collection != "":
		var coll: Collection = self.board.get_collection(collection)
		if coll != null:
			coll.remove_piece(self)
			collection = ""
			
static var piece_scene = preload("res://src/scenes/game_elements/gobjects/piece.tscn")			
## Constructor
static func construct(brd: Board, config: Dictionary) -> Piece:
	var piece: Piece = piece_scene.instantiate()
	piece.board = brd
	for prop in config.keys():
		piece.set(prop, config[prop])
	if "collection" in config:
		var c: Collection = brd.get_collection(config.collection)
		if c != null:
			piece.add_to_collection(c)
	brd.board_objects.add_child(piece)
	return piece

# Private methods

func _refresh_image() -> void:
	if image_up == "" or image_down == "":
		print("Image up or image down is empty")
		return
	if sprite_up.texture == null:
		sprite_up.texture = self.board.game.images[image_up]
	if sprite_down.texture == null:
		sprite_down.texture = self.board.game.images[image_down]
	
	# print("Hey.",self.gobject_scale)

	sprite_up.scale = self.gobject_scale / self.board.game.images[image_up].get_size()
	sprite_down.scale = self.gobject_scale / self.board.game.images[image_down].get_size()

	if face_up:
		sprite_up.show()
		sprite_down.hide()
	else:
		sprite_up.hide()
		sprite_down.show()

func can_access() -> bool:
	if collection == "":
		return true
	var _coll: Collection = self.board.get_collection(collection)
	if _coll != null:
		return _coll.can_access()
	return true

func set_selected(sl: bool) -> void:
	if sl == true:
		selected = true
		area2d.input_pickable = false
	else:
		selected = false
		area2d.input_pickable = true

func is_selected() -> bool:
	return selected



func _on_area_2d_mouse_entered() -> void:
	selectable = true


func _on_area_2d_mouse_exited() -> void:
	selectable = false

var selected: bool = false

var amount: int = 0

func _on_area_2d_input_event(_viewport:Node, event:InputEvent, _shape_idx:int) -> void:
	if event is InputEventMouseMotion:
		return
	
	if not board.board_player.is_selecting():
		if event.is_action_pressed("game_select") or (event.is_action_pressed("game_select_stack") and collection == ""):
			board.board_player.select_pieces([self])
		elif event.is_action_pressed("game_select_stack"):
			var coll: Collection = board.get_collection(collection)
			if coll != null and not coll.permanent:
				board.board_player.select_collections([coll])
	else:
		if (event.is_action_released("game_select") or event.is_action_released("game_select_stack")):
			if can_access():
				print("RELEASED AND STACKABLE OBJECT FOUND")
				board.board_player.stack_selection_to_item(self)


func _on_multiplayer_synchronizer_synchronized() -> void:
	_refresh_image()
