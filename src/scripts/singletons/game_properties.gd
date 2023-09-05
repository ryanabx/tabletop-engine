extends Node

enum SelectType {
	DRAG, TAP
}
enum MultiplayerMethod {
	P2P_SHORTENED, P2P
}
# View settings
var fullscreen: bool:
	set(val):
		if val == true:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	get:
		return (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

# In-game settings
var select_type: SelectType = SelectType.DRAG

# Multiplayer connection settings
var multiplayer_method: MultiplayerMethod = MultiplayerMethod.P2P_SHORTENED

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	print(get_property_list())
	if FileAccess.file_exists(Globals.SETTINGS_PATH):
		var settings_str: String = FileAccess.get_file_as_string(Globals.SETTINGS_PATH)
		var settings_dict: Dictionary = JSON.parse_string(settings_str)
		for prop in settings_dict.keys():
			set(prop, settings_dict[prop])
		print("Settings loaded!")

func save_settings() -> void:
	var settings_dict: Dictionary = {}
	for prop in get_property_list():
		settings_dict[prop.name] = get(prop.name)
	var settings_str: String = JSON.stringify(settings_dict)
	var s_save: FileAccess = FileAccess.open(Globals.SETTINGS_PATH, FileAccess.WRITE)
	s_save.store_string(settings_str)
	s_save.close()
	print("Settings saved!")