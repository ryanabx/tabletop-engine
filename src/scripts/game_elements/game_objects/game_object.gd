class_name GameObject
extends Node2D
## game_object.gd
## 
## Base game object class. Represents a singular entity on the board.
## 

# Shareable properties

## Represents the shape of an object, given a set of points.
var shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)])
## Represents the size of an object. Works with [param shape] to make the shape's boundaries on the board.
var size: Vector2 = Vector2.ONE
## Represents the type of the object. It is preferred to use this method of finding out the object type.
## See [enum Board.GameObjectType]
var object_type: Board.GameObjectType

# Private Variables

var _property_changes: Dictionary = {}
var board: Board # TODO: Make private with _

var _authority: int:
    get:
        return get_multiplayer_authority()
    set(val):
        if is_inside_tree() and multiplayer.get_unique_id() == val and _authority != val:
            set_authority.rpc(multiplayer.get_unique_id())
        set_multiplayer_authority(val)

func _set(property: StringName, value: Variant) -> bool:
    add_to_property_changes(property, value)
    return false

func add_to_property_changes(property: StringName, value: Variant) -> void:
    if is_inside_tree() and property in _get_shareable_properties() and is_multiplayer_authority():
        _property_changes[property] = value

func _get_shareable_properties() -> Array:
    return [
        "shape", "size", "position", "rotation"
    ]

@rpc("authority", "call_remote", "reliable")
func _property_changes_sync_rpc(props: Dictionary) -> void:
    for prop: String in props.keys():
        if prop == "inside":
            # print("Setting inside here!")
            var new_inside: Array[Dictionary] = []
            new_inside.assign(props[prop])
            props[prop] = new_inside
        set(prop, props[prop])

@rpc("any_peer", "call_remote", "reliable")
func set_authority(id: int) -> void:
    _authority = id

var index: int:
    get:
        return get_index()
    set(val):
        get_parent().move_child(self, val)
        add_to_property_changes("index", val)

## Moves this object to the top of the draw order
func move_self_to_top() -> void:
    index = -1

## Moves this object to the back of the draw order
func move_self_to_back() -> void:
    index = 0

func get_extents() -> PackedVector2Array:
    return get_main_transform() * shape

func get_main_transform() -> Transform2D:
    return Transform2D(rotation, size, 0.0, position)

func get_rect_extents() -> Rect2:
    return Rect2(position - size / 2, size)

func get_rect() -> Rect2:
    return Rect2(-size / 2, size)

func get_gobject_transform() -> Transform2D:
    return Transform2D().scaled(size)

func _ready() -> void:
    SignalManager.property_sync.connect(_sync_properties)

func _sync_properties() -> void:
    if is_multiplayer_authority() and not _property_changes.is_empty():
        _property_changes_sync_rpc.rpc(_property_changes)
    _property_changes = {}

func _process(_delta: float) -> void:
    pass

## Erase this game object.
func erase(recursive: bool = false) -> void:
    _erase_rpc.rpc(recursive)

@rpc("authority","call_local","reliable")
func _erase_rpc(_recursive: bool) -> void:
    queue_free()