extends MarginContainer

var current_screen_orientation: int = -5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if current_screen_orientation != DisplayServer.screen_get_orientation() and Utils.is_mobile_platform():
		_on_screen_orientation_changed()


func _on_screen_orientation_changed() -> void:
	var w_size: Vector2i = DisplayServer.screen_get_size()
	var orientation_extents: Rect2i = DisplayServer.get_display_safe_area()
	
	var margin_l: int = orientation_extents.position.x
	var margin_t: int = orientation_extents.position.y
	var margin_r: int = w_size.x - orientation_extents.size.x - margin_l
	var margin_b: int = w_size.y - orientation_extents.size.y - margin_t
	print("orientation_extents: ", orientation_extents, ", w_size: ", w_size, ", margin_l: ", margin_l, ", margin_t: ", margin_t, ", margin_r: ", margin_r, ", margin_b: ", margin_b)
	add_theme_constant_override("margin_left", margin_l)
	add_theme_constant_override("margin_top", margin_t)
	add_theme_constant_override("margin_right", margin_r)
	add_theme_constant_override("margin_bottom", margin_b)
	current_screen_orientation = DisplayServer.screen_get_orientation()