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

