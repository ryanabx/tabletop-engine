class_name Piece
extends Gobject

var image_up: String = ""
var image_down: String = ""
var collection: String = ""
var face_up: bool = false

@onready var sprite_down: Sprite2D = $Down
@onready var sprite_up: Sprite2D = $Up

func _ready() -> void:
	_refresh_image()

func _process(_delta: float) -> void:
	if collection != "":
		var coll: Collection = self.board.get_collection(collection)
		if coll != null:
			position = coll.position
			rotation = coll.rotation

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
	print("Adding piece ",name," to collection ",c_name)
	remove_from_collection()
	var coll: Collection = self.board.get_collection(c_name)
	if coll != null:
		coll.add_piece(self)
		collection = c_name
		coll.gobject_scale.x = maxf(gobject_scale.x, coll.gobject_scale.x)
		coll.gobject_scale.y = maxf(gobject_scale.y, coll.gobject_scale.y)

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
	
	print("Hey.",self.gobject_scale)

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
