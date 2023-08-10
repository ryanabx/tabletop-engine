class_name Collection
extends Gobject

var base_size: Vector2 = Vector2.ONE
var inside: Dictionary = {}
var view_perms: Array = []
var access_perms: Array = []
var permanent: bool = false
var force_state = null
var type: Type = Type.STACK

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

func load_data(data: Dictionary) -> void:
    for prop in data.keys():
        set(prop, data[prop])