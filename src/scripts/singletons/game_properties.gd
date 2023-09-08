extends Node

enum SelectType {
	DRAG, TAP
}
enum MultiplayerMethod {
	P2P_SHORTENED, P2P
}

var properties: Array[String] = [
	"fullscreen", "select_type", "multiplayer_method"
]

# View settings
var fullscreen: bool:
	set(val):
		if val == true:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		return true
	get:
		return (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

# In-game settings
var select_type: SelectType = SelectType.DRAG

# Multiplayer connection settings
var multiplayer_method: MultiplayerMethod = MultiplayerMethod.P2P_SHORTENED

func _ready() -> void:
	print("HI")
	load_settings()

func load_settings() -> void:
	if FileAccess.file_exists(Globals.SETTINGS_PATH):
		var settings_str: String = FileAccess.get_file_as_string(Globals.SETTINGS_PATH)
		var settings_dict: Dictionary = JSON.parse_string(settings_str)
		for prop: String in settings_dict.keys():
			set(prop, settings_dict[prop])
	print("Settings loaded!")

func save_settings() -> void:
	var settings_dict: Dictionary = {}
	for prop: String in properties:
		settings_dict[prop] = get(prop)
	var settings_str: String = JSON.stringify(settings_dict)
	var s_save: FileAccess = FileAccess.open(Globals.SETTINGS_PATH, FileAccess.WRITE)
	s_save.store_string(settings_str)
	s_save.close()
	print("Settings saved!")