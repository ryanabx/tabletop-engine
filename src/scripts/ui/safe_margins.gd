extends MarginContainer

func _ready() -> void:
	SignalManager.orientation_changed.connect(_screen_orientation_changed)
	_screen_orientation_changed()

func _screen_orientation_changed() -> void:
	add_theme_constant_override("margin_left", Globals.safe_margin_l)
	add_theme_constant_override("margin_top", Globals.safe_margin_t)
	add_theme_constant_override("margin_right", Globals.safe_margin_r)
	add_theme_constant_override("margin_bottom", Globals.safe_margin_b)