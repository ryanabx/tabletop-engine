extends Node

var request: HTTPRequest

func _ready() -> void:
    GameProperties.load_settings()
    request = HTTPRequest.new()
    add_child(request)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_exit_fullscreen") and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        GameProperties.save_settings()

func _process(delta: float) -> void:
    if Utils.current_safe_area != DisplayServer.get_display_safe_area():
        Utils.on_screen_orientation_changed()


# Game menu creation
signal game_menu_create_piece(piece: Piece)
signal game_menu_create_collection(collection: Collection)
signal game_menu_destroy()

# Menubar Signals
signal create_load_config_dialog()
signal create_export_config_dialog()
signal run_action(index: int)

# Dialogs
signal server_add_peer()
signal client_add_peer()

# Orientation changed
signal orientation_changed()

# File Dialogs
signal config_file_opened(fname: String)

signal download_config_popup()

signal export_config_created(bytes: PackedByteArray)


# Game Loading
signal game_percent_loaded(pc: float)
signal game_load_started()
signal game_load_finished(board: Board)

# Scene Transition
signal scene_transition(scene: String)

# Configs
signal config_added()


# Multiplayer

signal property_sync()