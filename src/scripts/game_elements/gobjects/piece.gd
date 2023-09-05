class_name Piece
extends Selectable

var image_up: String = ""
var image_down: String = ""
var types: Array = []

var _face_up: bool = false
var face_up: bool:
	get:
		return _face_up
	set(val):
		_face_up = val
		_refresh_image()

var grab_offset: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D

func _ready() -> void:
	# Sprite stuff
	sprite = Sprite2D.new()
	add_child(sprite)
	_refresh_image()
	super._ready()

@rpc("any_peer","call_local","reliable")
func erase_self() -> void:
	queue_free()

# Private methods

func _refresh_image() -> void:
	if image_up == "" or image_down == "":
		print("Image up or image down is empty")
		return
	if board == null or board.game == null\
		or not image_up in board.game.include_images or not image_down\
		in board.game.include_images or not is_instance_valid(sprite):
		return
	
	sprite.texture = board.game.include_images[image_up] if face_up else board.game.include_images[image_down]
	sprite.scale = size / sprite.texture.get_size()

func can_access() -> bool:
	return true

var amount: int = 0

func _on_select(_event:InputEvent) -> void:
	board.board_player.queue_select_object(self)

func _on_deselect(_event: InputEvent) -> void:
	if can_access():
		board.board_player.stack_selection_to_item(self)

func _on_multiplayer_synchronizer_synchronized() -> void:
	_refresh_image()
