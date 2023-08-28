class_name GameObject
extends Node2D

var shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)])
var gobject_scale: Vector2 = Vector2.ONE

var board: Board

var auth: int:
    get:
        return get_multiplayer_authority()
    set(val):
        if auth != val:
            print("MY_ID: ",multiplayer.get_unique_id()," SET_AUTH: ",val," ON ",get_name())
            set_multiplayer_authority(val)
            if val == multiplayer.get_unique_id():
                set_authority.rpc(val)

@rpc("any_peer","call_remote","reliable")
func set_authority(id: int) -> void:
    auth = id

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

func get_extents() -> PackedVector2Array:
    return get_main_transform() * shape

func get_main_transform() -> Transform2D:
    return Transform2D(rotation, gobject_scale, 0.0, position)

func get_rect_extents() -> Rect2:
    return Rect2(position - scale / 2, scale)

func get_rect() -> Rect2:
    return Rect2(-scale / 2, scale)

func get_gobject_transform() -> Transform2D:
    return Transform2D().scaled(gobject_scale)