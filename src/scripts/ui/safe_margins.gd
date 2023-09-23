extends MarginContainer

func _ready() -> void:
    GameManager.orientation_changed.connect(_screen_orientation_changed)
    _screen_orientation_changed()

func _screen_orientation_changed() -> void:
    add_theme_constant_override("margin_left", Global.safe_margin_l)
    add_theme_constant_override("margin_top", Global.safe_margin_t)
    add_theme_constant_override("margin_right", Global.safe_margin_r)
    add_theme_constant_override("margin_bottom", Global.safe_margin_b)