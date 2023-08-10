class_name Gobject
extends RefCounted

var position: Vector2 = Vector2.ZERO
var rotation: float = 0.0
var scale: Vector2 = Vector2.ONE
var name: String = ""
var shape: PackedVector2Array = PackedVector2Array([Vector2(-0.5,-0.5), Vector2(-0.5,0.5), Vector2(0.5,0.5), Vector2(0.5,-0.5)])
var z_index: float = 0.0
var placeholder: bool = false
var erased: bool = false