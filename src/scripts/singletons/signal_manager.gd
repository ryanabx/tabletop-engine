extends Node

# Right click menu creation
signal game_menu_create(type: RightClickMenu.TYPE, objects: Array)
signal game_menu_destroy()

# Right click menu commands
signal move_items_to_front(objects: Array)
signal move_items_to_back(objects: Array)
signal shuffle_items(objects: Array)
signal convert_to_stack(objects: Array)

# Menubar Signals
signal create_load_config_dialog()
signal reset_tabletop()

# File Dialogs
signal config_file_opened(fname: String)