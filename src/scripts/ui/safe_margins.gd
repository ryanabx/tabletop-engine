extends MarginContainer

signal orientation_changed()

static var current_safe_area: Rect2i = Rect2i(0, 0, 0, 0)

func _ready() -> void:
    orientation_changed.connect(_screen_orientation_changed)
    on_screen_orientation_changed()

func _process(_delta: float) -> void:
    if (current_safe_area != DisplayServer.get_display_safe_area()):
        on_screen_orientation_changed()
        orientation_changed.emit()

func _screen_orientation_changed() -> void:
    add_theme_constant_override("margin_left", Global.safe_margin_l)
    add_theme_constant_override("margin_top", Global.safe_margin_t)
    add_theme_constant_override("margin_right", Global.safe_margin_r)
    add_theme_constant_override("margin_bottom", Global.safe_margin_b)

func on_screen_orientation_changed() -> void:
    var w_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.get_primary_screen())
    var orientation_extents: Rect2i = DisplayServer.get_display_safe_area()
    
    var margin_l: int = orientation_extents.position.x
    var margin_t: int = orientation_extents.position.y
    var margin_r: int = w_size.x - orientation_extents.size.x - margin_l
    var margin_b: int = w_size.y - orientation_extents.size.y - margin_t
    Global.safe_margin_l = margin_l
    Global.safe_margin_t = margin_t
    Global.safe_margin_r = margin_r
    Global.safe_margin_b = margin_b
    current_safe_area = DisplayServer.get_display_safe_area()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_exit_fullscreen") and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        GameProperties.save_settings()