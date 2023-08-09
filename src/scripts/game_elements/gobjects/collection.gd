class_name Collection
extends Gobject

@export var base_size: Vector2 = Vector2.ONE
@export var inside: Array[String] = []
@export var view_perms: Array = []
@export var access_perms: Array = []
@export var permanent: bool = false
@export var force_state: bool = false
@export var type: Type = Type.STACK

enum Type {STACK, HAND}


