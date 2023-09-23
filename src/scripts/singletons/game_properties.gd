class_name GameProperties
extends Node

enum SelectType {
    DRAG, TAP
}
enum MultiplayerMethod {
    P2P_SHORTENED, P2P
}

static var properties: Array[String] = [
    "fullscreen", "select_type", "multiplayer_method"
]

# View settings
static var fullscreen: bool:
    set(val):
        if val == true:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        else:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
        return true
    get:
        return (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

# In-game settings

# Multiplayer connection settings
static var multiplayer_method: MultiplayerMethod = MultiplayerMethod.P2P_SHORTENED

static func load_settings() -> void:
    if FileAccess.file_exists(Global.SETTINGS_PATH):
        var settings_str: String = FileAccess.get_file_as_string(Global.SETTINGS_PATH)
        var settings_dict: Dictionary = JSON.parse_string(settings_str)
        for prop: String in settings_dict.keys():
            if prop in GameProperties:
                GameProperties.set_static(prop, settings_dict[prop])
    # print("Settings loaded!")

static func save_settings() -> void:
    var settings_dict: Dictionary = {}
    for prop: String in properties:
        settings_dict[prop] = get_static(prop)
    var settings_str: String = JSON.stringify(settings_dict)
    var s_save: FileAccess = FileAccess.open(Global.SETTINGS_PATH, FileAccess.WRITE)
    s_save.store_string(settings_str)
    s_save.close()
    # print("Settings saved!")