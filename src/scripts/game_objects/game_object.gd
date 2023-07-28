class_name GameObject
extends Node2D

var highlighted = false

func get_extents() -> Rect2:
	return get_rect() * get_transform().affine_inverse()

func get_rect() -> Rect2:
	print("get_rect Not Implemented on: ",get_class())
	return Rect2(0.0, 0.0, 0.0, 0.0)

func flip() -> void:
	print("flip Not Implemented on: ",get_class())

func highlight() -> void:
	highlighted = true

func dehighlight() -> void:
	highlighted = false

func _draw() -> void:
	if highlighted:
		draw_rect(Utils.rect_with_padding(get_rect(), Globals.OBJECT_HIGHLIGHT_PADDING), Globals.OBJECT_HIGHLIGHT_COLOR, false, Globals.OBJECT_HIGHLIGHT_BORDER)