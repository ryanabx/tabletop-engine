class_name GameObject
extends Node2D
## game_object.gd
## 
## Base game object class. Represents a singular entity on the board.
## 

# Shareable properties

## Represents the type of the object. It is preferred to use this method of finding out the object type.
var type: String
## Tags for this Game Object
var tags: Array[String]

# ATTRIBUTES
var attributes: Dictionary = {}

# Private Variables

var _shareable_properties: Array[String] = ["position", "rotation", "tags", "type"]
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
    if is_inside_tree() and property in _shareable_properties and is_multiplayer_authority():
        _property_changes[property] = value

@rpc("authority", "call_remote", "reliable")
func _property_changes_sync_rpc(props: Dictionary) -> void:
    for prop: String in props.keys():
        if prop == "inside":
            # print("Setting inside here!")
            var new_inside: Array[Dictionary] = []
            var arr: Array = props[prop]
            new_inside.assign(arr)
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

func _ready() -> void:
    board.property_sync.connect(_sync_properties)
    # Attributes
    for trt: Attribute in attributes.values():
        _shareable_properties.append_array(trt.shareable_properties())

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

func get_attribute(attr: String) -> Variant:
    return attributes[attr] if attr in attributes else null

func add_attribute(attr: Attribute) -> void:
    attributes[attr.name()] = attr

func remove_attribute(idntfr: String) -> void:
    # TODO: Remove changeable properties as well
    attributes.erase(idntfr)

func get_prop(prop: StringName) -> Variant:
    if "::" in prop:
        var prop_split: Array = prop.split("::")
        if get_attribute(prop_split[0]):
            return get_attribute(prop_split[0]).get(prop_split[1])
        else:
            return null
    return get(prop)

func serialize_object() -> Dictionary:
    var _dict: Dictionary = {}
    for prop: String in _shareable_properties:
        _dict[prop] = get_prop(prop)
    return _dict

func deserialize_object(dict: Dictionary) -> GameObject:
    return board.new_game_object(dict)