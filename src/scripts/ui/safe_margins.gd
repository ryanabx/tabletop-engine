extends MarginContainer

signal orientation_changed()

func _ready() -> void:
    orientation_changed.connect(_screen_orientation_changed)
    _screen_orientation_changed()

func _process(_delta: float) -> void:
    if (Utils.current_safe_area != DisplayServer.get_display_safe_area()):
        Utils.on_screen_orientation_changed()
        orientation_changed.emit()

func _screen_orientation_changed() -> void:
    add_theme_constant_override("margin_left", Global.safe_margin_l)
    add_theme_constant_override("margin_top", Global.safe_margin_t)
    add_theme_constant_override("margin_right", Global.safe_margin_r)
    add_theme_constant_override("margin_bottom", Global.safe_margin_b)