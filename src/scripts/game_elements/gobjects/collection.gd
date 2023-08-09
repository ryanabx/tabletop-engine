class_name Collection
extends Gobject

@export var base_size: Vector2 = Vector2.ONE
@export var inside: Array = []
@export var view_perms: Array = []
@export var access_perms: Array = []
@export var permanent: bool = false
@export var force_state: bool = false
@export var type: Type = Type.STACK

enum Type {STACK, HAND}

func serialize() -> Dictionary:
    var result: Dictionary = {}
    for prop in get_property_list():
        var _n: StringName = prop.name
        result[_n] = get(_n)
    return result

static func deserialize(_d: Dictionary) -> Collection:
    var piece: Collection = Collection.new()
    for prop in _d.keys():
        piece.set(prop, _d[prop])
    return piece
