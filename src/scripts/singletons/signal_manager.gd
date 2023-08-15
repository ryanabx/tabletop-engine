extends Node

# Game menu creation
signal game_menu_create(objects: Array)
signal game_menu_destroy()

# Game menu commands
signal shuffle_selection(objects: Array)
signal convert_to_stack(objects: Array)
signal select_objects(objects: Array, with_collections: bool)

# Menubar Signals
signal create_load_config_dialog()
signal create_export_config_dialog()
signal open_multiplayer_menu()
signal run_action(index: int)

# File Dialogs
signal config_file_opened(fname: String)
signal export_conf(config: Resource)
signal load_game_config(config: Resource)

# Game Loading
signal game_percent_loaded(pc: float)
signal game_load_started()
signal game_load_finished()
