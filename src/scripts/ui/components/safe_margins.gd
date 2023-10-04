extends MarginContainer


signal orientation_changed()

var current_safe_area: Rect2i = Rect2i(0, 0, 0, 0)

func _ready() -> void:
    orientation_changed.connect(_screen_orientation_changed)

func _process(_delta: float) -> void:
    if (current_safe_area != DisplayServer.get_display_safe_area() and not GlobalBridge.global.IsDesktopPlatform()):
        on_screen_orientation_changed()

func _screen_orientation_changed() -> void:
    add_theme_constant_override("margin_left", GlobalBridge.global.SafeMarginLeft)
    add_theme_constant_override("margin_top", GlobalBridge.global.SafeMarginTop)
    add_theme_constant_override("margin_right", GlobalBridge.global.SafeMarginRight)
    add_theme_constant_override("margin_bottom", GlobalBridge.global.SafeMarginBottom)

func on_screen_orientation_changed() -> void:
    var w_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.get_primary_screen())
    var orientation_extents: Rect2i = DisplayServer.get_display_safe_area()
    
    var margin_l: int = orientation_extents.position.x
    var margin_t: int = orientation_extents.position.y
    var margin_r: int = w_size.x - orientation_extents.size.x - margin_l
    var margin_b: int = w_size.y - orientation_extents.size.y - margin_t
    GlobalBridge.global.SafeMarginLeft = margin_l
    GlobalBridge.global.SafeMarginTop = margin_t
    GlobalBridge.global.SafeMarginRight = margin_r
    GlobalBridge.global.SafeMarginBottom = margin_b
    current_safe_area = DisplayServer.get_display_safe_area()
    print("Changed")
    orientation_changed.emit()

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_exit_fullscreen") and not GlobalBridge.global.GetUserSetting("fullscreen"):
        GlobalBridge.global.SetUserSetting("fullscreen", false)
