class_name GameObjectAPI
extends RefCounted

var _obj: GameObject

func _init(obj: GameObject) -> void:
    _obj = obj
    _obj.tree_exited.connect(free)