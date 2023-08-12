class_name Collection
extends Gobject

var base_size: Vector2 = Vector2.ONE
var inside: Dictionary = {}
var view_perms: Array = []
var access_perms: Array = []
var permanent: bool = false
var force_state = null
var type: Type = Type.STACK

var selected: bool = false
@onready var collision_polygon = $Area2D/CollisionPolygon2D

enum Type {STACK, HAND}

@onready var count: Label = $Count

func _ready() -> void:
	collision_polygon.polygon = get_gobject_transform() * self.shape

func _process(_delta: float) -> void:
	count.position = (get_gobject_transform() * self.shape)[0]
	count.text = str(name,"[",inside.size(),"]")
	queue_redraw()

func _draw() -> void:
	draw_colored_polygon(get_gobject_transform() * self.shape, Color.BLACK * Color(1,1,1,0.3))

func add_piece(piece: Piece) -> void:
	inside[piece.name] = true

func remove_piece(piece: Piece) -> void:
	inside.erase(piece.name)
	if inside.is_empty() and not permanent:
		if is_multiplayer_authority():
			erase_self.rpc()

func get_pieces() -> Array[Piece]:
	return board.get_pieces(inside.keys())

@rpc("authority","call_local","reliable")
func erase_self() -> void:
	for obj in inside:
		var piece: Piece = self.board.get_piece(obj)
		if piece != null:
			piece.collection = ""

	queue_free()

static var collection_scene = preload("res://src/scenes/game_elements/gobjects/collection.tscn")
## Constructor
static func construct(brd: Board, config: Dictionary) -> Collection:
	var collection: Collection = collection_scene.instantiate()
	collection.board = brd
	for prop in config.keys():
		collection.set(prop, config[prop])
	brd.board_objects.add_child(collection)
	for key in collection.inside.keys():
		var piece: Piece = brd.get_piece(key)
		if piece != null:
			piece.add_to_collection(collection)
	return collection

func can_access() -> bool:
	if access_perms.size() <= Player.get_id():
		return true # Default to true if there's no access perms
	elif access_perms[Player.get_id()] == false:
		return false
	return true


func _on_area_2d_mouse_entered() -> void:
	pass # Replace with function body.


func _on_area_2d_mouse_exited() -> void:
	pass # Replace with function body.



func _on_area_2d_input_event(_viewport:Node, event:InputEvent, _shape_idx:int) -> void:
	match board.board_player.input_state:
		board.board_player.InputState.HANDLED:
			return
		board.board_player.InputState.UNHANDLED:
			input_unhandled(event)

func input_unhandled(event: InputEvent) -> void:
	if board.board_player.selected_pieces.is_empty():
		return


	if (event.is_action_released("game_select") or event.is_action_released("game_select_stack")):
		if selected == false and can_access():
			print("RELEASED AND STACKABLE OBJECT FOUND")
			board.board_player.stack_stackables_to_collection(self)
