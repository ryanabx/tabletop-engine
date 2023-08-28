extends Node

# Game menu creation
signal game_menu_create_piece(piece: Piece)
signal game_menu_create_collection(collection: Collection)
signal game_menu_destroy()

# Menubar Signals
signal create_load_config_dialog()
signal create_export_config_dialog()
signal open_multiplayer_menu()
signal run_action(index: int)

# Camera move
signal camera_move_start()
signal camera_move_end()

# Dialogs
signal server_add_peer()
signal client_add_peer()

# Orientation changed
signal orientation_changed()

# File Dialogs
signal config_file_opened(fname: String)
signal export_conf(config: PackedByteArray)
signal load_game_config(config: GameConfig2)

# Game Loading
signal game_percent_loaded(pc: float)
signal game_load_started()
signal game_load_finished(board: Board)

# Scene Transition
signal scene_transition(scene: String)
