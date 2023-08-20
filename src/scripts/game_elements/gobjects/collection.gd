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
@onready var area2d: Area2D = $Area2D

enum Type {STACK, HAND}

@onready var count: Label = $Count

func _ready() -> void:
	collision_polygon.polygon = get_gobject_transform() * self.shape
	count.z_index = 1000

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


func set_selected(sl: bool) -> void:
	if sl == true:
		selected = true
		area2d.collision_layer = 2
	else:
		selected = false
		area2d.collision_layer = 1

func _on_select(_event:InputEvent) -> void:
	pass

func _on_deselect(event:InputEvent) -> void:
	if event is InputEventMouseMotion:
		return

	if board.board_player.is_selecting():
		if (event.is_action_released("game_select") or event.is_action_released("game_select_stack")):
			if selected == false and can_access():
				print("RELEASED AND STACKABLE OBJECT FOUND")
				board.board_player.stack_stackables_to_collection(self)
