class_name Piece
extends Gobject

@export var image_up: String = ""
@export var image_down: String = ""
@export var collection: String = ""
@export var face_up: bool = false


func serialize() -> Dictionary:
    var result: Dictionary = {}
    for prop in get_property_list():
        var _n: StringName = prop.name
        result[_n] = get(_n)
    return result

static func deserialize(_d: Dictionary) -> Piece:
    var piece: Piece = Piece.new()
    for prop in _d.keys():
        piece.set(prop, _d[prop])
    return piece