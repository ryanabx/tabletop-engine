class_name Gobject
extends RefCounted

@export var position: Vector2 = Vector2.ZERO
@export var rotation: float = 0.0
@export var scale: Vector2 = Vector2.ONE
@export var name: String = ""
@export var shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)])
@export var z_index: float = 0.0
@export var placeholder: bool = false
@export var erased: bool = false