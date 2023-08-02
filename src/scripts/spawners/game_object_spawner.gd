class_name GameObjectSpawner
extends MultiplayerSpawner

@onready var piece_scene: PackedScene = preload("res://src/scenes/game_elements/spawnables/piece.tscn")
@onready var collection_scene: PackedScene = preload("res://src/scenes/game_elements/spawnables/collection.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_spawn_function(Callable(self, "spawn_game_object"))

func spawn_game_object(obj: Dictionary) -> GameObject:
	if "type" not in obj:
		print("Error: object does not contain a type")
		return piece_scene.instantiate()
	match obj.type:
		"piece":
			return new_piece(obj, obj.coordinate_scale, obj.id)
		"stack":
			return new_collection(obj, obj.coordinate_scale, obj.id)
		"hand":
			return new_collection(obj, obj.coordinate_scale, obj.id)
		_:
			print("Huh?")
			return piece_scene.instantiate()

func new_piece(obj: Dictionary, coordinate_scale: Vector2, id: int) -> Piece:
	var piece: Piece = piece_scene.instantiate()
	if "name" in obj:
		piece.add_to_group(obj.name)
	piece.set_name(str("Piece_",id))
	# Piece transforms
	piece.position = Vector2(obj.position.x, obj.position.y) * coordinate_scale if "position" in obj else Vector2.ZERO
	piece.rotation_degrees = obj.rotation if "rotation" in obj else 0.0
	# Piece exclusives
	piece.image_up_string = obj.image_up
	piece.image_down_string = obj.image_down
	piece.set_side(obj.face_up)
	piece.set_sprite_scale(Vector2(obj.scale.x, obj.scale.y) * coordinate_scale if "scale" in obj else Vector2.ONE)
	# Add child
	if "collection" in obj:
		var coll: Collection = (get_tree().get_nodes_in_group(obj.collection)[0] as Collection)
		coll.add_game_object_to_top(piece)
		piece.position = coll.position
	return piece

func new_collection(obj: Dictionary, coordinate_scale: Vector2, id: int) -> Collection:
	var collection: Collection = collection_scene.instantiate()
	match obj.type:
		"hand": collection.type = Collection.TYPE.HAND
		"stack": collection.type = Collection.TYPE.STACK
		_: return
	if "name" in obj:
		collection.add_to_group(obj.name)
	collection.set_name(str("Collection_",id))
	# Collection transforms
	collection.position = Vector2(obj.position.x, obj.position.y) * coordinate_scale if "position" in obj else Vector2.ZERO
	collection.base_size = Vector2(obj.scale.x, obj.scale.y) * coordinate_scale if "scale" in obj else Vector2.ONE
	collection._scale = Vector2(obj.scale.x, obj.scale.y) * coordinate_scale if "scale" in obj else Vector2.ONE
	collection.rotation_degrees = obj.rotation if "rotation" in obj else 0.0
	# Collection exclusives
	if "permanent" in obj:
		collection.permanent = obj.permanent
	if "force_state" in obj:
		collection.force_state = obj.force_state
	if "view_perms" in obj:
		collection.view_perms = obj.view_perms
	if "access_perms" in obj:
		collection.access_perms = obj.access_perms
	return collection

static func make_stack_config(position: Vector2) -> Dictionary:
	var obj: Dictionary = {
		"id": Globals.piece_id,
		"coordinate_scale": Vector2.ONE,
		"type": "stack",
		"position": {
			"x": position.x,
			"y": position.y
		}
	}
	Globals.piece_id += 1
	return obj
