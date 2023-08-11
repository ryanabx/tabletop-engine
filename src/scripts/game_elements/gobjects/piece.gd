class_name Piece
extends Gobject

var image_up: String = ""
var image_down: String = ""
var collection: String = ""
var face_up: bool = false

@onready var sprite_down: Sprite2D = $Down
@onready var sprite_up: Sprite2D = $Up

@onready var collision_polygon = $Area2D/CollisionPolygon2D

var selectable: bool = false

func _ready() -> void:
	_refresh_image()
	collision_polygon.polygon = get_gobject_transform() * self.shape


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
	if is_multiplayer_authority():
		face_up = _face_up
	_refresh_image()

## Flips the object's face
func flip() -> void:
	if is_multiplayer_authority():
		face_up = not face_up
	_refresh_image()

## Adds this piece to a collection with the name c_name
func add_to_collection(c_name: String) -> void:
	remove_from_collection()
	var coll: Collection = self.board.get_collection(c_name)
	if coll != null:
		coll.add_piece(self)
		collection = c_name
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
			piece.add_to_collection(c.name)
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


func _on_area_2d_mouse_entered() -> void:
	selectable = true


func _on_area_2d_mouse_exited() -> void:
	selectable = false

var selected: bool = false

# func _unhandled_input(event: InputEvent) -> void:
# 	if selectable == true and not selected == true and board.board_player.selected_pieces.is_empty():
# 		get_viewport().set_input_as_handled()
# 		if not selected and event.is_action_pressed("game_select"):
# 			remove_from_collection()
# 			print(name," clicked ",amount, " index ",get_index())
# 			board.board_player.select_pieces([self])
# 	elif selected == true:
# 		get_viewport().set_input_as_handled()
# 		if event.is_action_released("game_select"):
# 			board.board_player.deselect_pieces()
# 		elif event is InputEventMouseMotion:
# 			position = board.get_local_mouse_position().clamp(board.border.position, board.border.end)
# 			if collection != "":
# 				var c: Collection = board.get_collection(collection)
# 				if c != null:
# 					c.position = position

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and selected == true:
		position = board.get_local_mouse_position().clamp(board.border.position, board.border.end)
		if collection != "":
			var c: Collection = board.get_collection(collection)
			if c != null:
				c.position = position


var amount: int = 0


func _on_area_2d_input_event(_viewport:Node, event:InputEvent, _shape_idx:int) -> void:
	if board.board_player.input_state == board.board_player.InputState.HANDLED:
		return
	
	match board.board_player.input_state:
		board.board_player.InputState.HANDLED:
			return
		board.board_player.InputState.UNHANDLED:
			input_unhandled(event)
		board.board_player.InputState.STACKABLE:
			input_stackable(event)

func input_unhandled(event: InputEvent) -> void:
	if board.board_player.selected_pieces.is_empty():
		if event.is_action_pressed("game_select") or (event.is_action_pressed("game_select_stack") and collection == ""):
			remove_from_collection()
			print(name," clicked ",amount, " index ",get_index())
			board.board_player.select_pieces([self])
			board.board_player.input_state = board.board_player.InputState.HANDLED
		elif event.is_action_pressed("game_select_stack"):
			var coll: Collection = board.get_collection(collection)
			if coll != null:
				print(name," clicked ",amount, " index ", get_index())
				board.board_player.select_collections([coll])
			board.board_player.input_state = board.board_player.InputState.HANDLED
	if not event is InputEventMouseMotion:
		print("Event: ", event)


	if event.is_action_released("game_select") and selected == true:
		print("RELEASED")
		board.board_player.deselect_pieces()
		board.board_player.input_state = board.board_player.InputState.STACKABLE

func input_stackable(event: InputEvent) -> void:
	if event.is_action_released("game_select") and selected == false:
		print("STACKABLE OBJECT FOUND")
		board.board_player.input_state = board.board_player.InputState.HANDLED
