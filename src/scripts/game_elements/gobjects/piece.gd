class_name Piece
extends GameObject

var image_up: String = ""
var image_down: String = ""
var _face_up: bool = false
var face_up: bool:
	get:
		return _face_up
	set(val):
		_face_up = val
		_refresh_image()

@rpc("any_peer","call_remote","reliable")
func set_authority(id: int) -> void:
	auth = id

var grab_offset: Vector2 = Vector2.ZERO

@onready var sprite_down: Sprite2D = $Down
@onready var sprite_up: Sprite2D = $Up

@onready var collision_polygon: CollisionPolygon2D = $Area2D/CollisionPolygon2D
@onready var area2d: Area2D = $Area2D

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

## Adds this piece to a collection with the name c_name
func add_to_collection(coll: Collection) -> void:
	if coll != null:
		auth = multiplayer.get_unique_id()
		coll.auth = multiplayer.get_unique_id()
		coll.add_piece(self)

@rpc("any_peer","call_local","reliable")
func erase_self() -> void:
	queue_free()
			
static var piece_scene = preload("res://src/scenes/game_elements/gobjects/piece.tscn")			
## Constructor
static func construct(brd: Board, config: Dictionary) -> Piece:
	if "collection" in config and config.collection != "":
		# Serialize and add to collection
		var c: Collection = brd.get_collection(config.collection)
		var _dict: Dictionary = {
			"name": config.name,
			"image_up": config.image_up if "image_up" in config else "",
			"image_down": config.image_down if "image_down" in config else "",
			"face_up": config.face_up if "face_up" in config else false,
			"shape": config.shape if "shape" in config else PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)]),
			"gobject_scale": config.gobject_scale if "gobject_scale" in config else Vector2.ONE
		}
		if c != null:
			c.auth = brd.multiplayer.get_unique_id()
			c.inside.append(_dict)
			return null
		else:
			print("ERROR: Piece made before collection. Could not find collection ",config.collection)
	# Else, create an object
	config.erase("collection")
	var piece: Piece = piece_scene.instantiate()
	piece.board = brd
	for prop in config.keys():
		piece.set(prop, config[prop])
	brd.board_objects.add_child(piece)
	return piece

# Private methods

func _refresh_image() -> void:
	if image_up == "" or image_down == "":
		print("Image up or image down is empty")
		return
	if board == null or board.game == null\
		or not image_up in board.game.images or not image_down\
		in board.game.images or not is_instance_valid(sprite_up)\
		or not is_instance_valid(sprite_down):
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
	return true

func set_selected(sl: bool) -> void:
	auth = multiplayer.get_unique_id()
	if sl == true:
		selected = true
		area2d.collision_layer = 2
	else:
		selected = false
		area2d.collision_layer = 1

func is_selected() -> bool:
	return selected

var selected: bool = false

var amount: int = 0

func _on_select(_event:InputEvent) -> void:
	board.board_player.queue_select_object(self)

func _on_deselect(_event: InputEvent) -> void:
	if can_access():
		print("RELEASED AND STACKABLE OBJECT FOUND")
		board.board_player.stack_selection_to_item(self)

func _on_multiplayer_synchronizer_synchronized() -> void:
	_refresh_image()
