class_name Global
extends RefCounted

static var has_setup: bool = false

const SPLASHES: Array[String] = [
    '"Because fuck Tabletop Simulator"!',
    'Vegan, if you so choose!',
    'You have UNO, you fucking dick!',
    'Fruit salad, yummy yummy!',
    'Can I drown myself? -Jacob',
    'Since your ass wanna act onions'
]

# MULTIPLAYER
const DEFAULT_MAX_PLAYERS: int = 4

const GRAB_THRESHOLD: float = 40.0

const COLLECTION_OUTLINE: int = 2

const ICE_SERVERS: Dictionary = {
    "iceServers": [
        {
            "urls": [
                "stun.l.google.com:19302",
                "iphone-stun.strato-iphone.de:3478",
                "numb.viagenie.ca:3478",
                "s1.taraba.net:3478",
                "s2.taraba.net:3478",
                "stun.12connect.com:3478",
                "stun.12voip.com:3478",
                "stun.1und1.de:3478",
                "stun.2talk.co.nz:3478",
                "stun.2talk.com:3478",
                "stun.3clogic.com:3478",
                "stun.3cx.com:3478",
                "stun.a-mm.tv:3478",
                "stun.aa.net.uk:3478",
                "stun.acrobits.cz:3478"
                ]
        },
        {
        "urls": ["stun:stun.relay.metered.ca:80"]
          },
        {
            "urls": 'turn:numb.viagenie.ca',
            "credential": 'muazkh',
            "username": 'webrtc@live.com'
        },
        {
            "urls": 'turn:192.158.29.39:3478?transport=udp',
            "credential": 'JZEOEt2V3Qb0y27GRntt2u2PAYA=',
            "username": '28224511:1379330808'
        },
        {
            "urls": 'turn:192.158.29.39:3478?transport=tcp',
            "credential": 'JZEOEt2V3Qb0y27GRntt2u2PAYA=',
            "username": '28224511:1379330808'
        },
        {
            "urls": 'turn:turn.bistri.com:80',
            "credential": 'homeo',
            "username": 'homeo'
        },
        {
            "urls": 'turn:turn.anyfirewall.com:443?transport=tcp',
            "credential": 'webrtc',
            "username": 'webrtc'
        },
          {
            "urls": "turn:a.relay.metered.ca:80",
            "username": "b7153991e76085c83420f473",
            "credential": "S7apm/MC4QIFJG4C",
        },
        {
            "urls": "turn:a.relay.metered.ca:80?transport=tcp",
            "username": "b7153991e76085c83420f473",
            "credential": "S7apm/MC4QIFJG4C",
        },
        {
            "urls": "turn:a.relay.metered.ca:443",
            "username": "b7153991e76085c83420f473",
            "credential": "S7apm/MC4QIFJG4C",
        },
        {
            "urls": "turn:a.relay.metered.ca:443?transport=tcp",
            "username": "b7153991e76085c83420f473",
            "credential": "S7apm/MC4QIFJG4C",
        }
    ]
}

static var load_this_game: PackedByteArray = PackedByteArray([])

static var safe_margin_l: int = 0
static var safe_margin_t: int = 0
static var safe_margin_r: int = 0
static var safe_margin_b: int = 0

const TRANSITION_TIME_IN: float = 0.125
const TRANSITION_TIME_OUT: float = 0.125

# THEMING GLOBALS

const BASE_SCALE: float = 1.0

const SCREEN_SIZE = Vector2(1280.0, 720.0)

const OUTLINE_THICKNESS: float = 6.0
const THICKNESS_RATIO: float = 0.8

const SELECTION_BOX_OUTLINE: float = 2.0

# UserInterface.gd
const GAME_NAME_PADDING: float = 2.0

# GameObject.gd
const OBJECT_HIGHLIGHT_BORDER: float = 2.0
const OBJECT_HIGHLIGHT_PADDING: float = 6.0
const OBJECT_HIGHLIGHT_COLOR: Color = Color.WHITE

# OTHER GLOBALS
const GAME_VERSION: String = "0.0.1"
const CURRENT_API_VERSION: int = 1

# FILE PATHS

const CONFIG_REPO: String = "user://configs"
const CONFIG_EXTENSION: String = ".tbt"

const DEFAULT_CONFIG_PATH: String = "res://configs/default%s" % CONFIG_EXTENSION

const SETTINGS_PATH: String = "user://settings.json"

# COLORS

const COLOR_TRANSPARENT_HIGHLIGHT = Color(1.0, 1.0, 1.0, 0.2)
const COLOR_SELECTED: Color = Color.AZURE
const COLOR_HIGHLIGHTED: Color = Color.ALICE_BLUE * COLOR_TRANSPARENT_HIGHLIGHT
const COLOR_PERMANENT: Color = Color.BLACK
const COLOR_SELECTION_BOX_BORDER: Color = Color.BLUE
const COLOR_SELECTION_BOX: Color = COLOR_SELECTION_BOX_BORDER * COLOR_TRANSPARENT_HIGHLIGHT

static func is_desktop_platform() -> bool:
    return [
        "Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"
    ].has(OS.get_name())

static func is_web_platform() -> bool:
    return [
        "Web"
    ].has(OS.get_name())

static func is_mobile_platform() -> bool:
    return [
        "iOS", "Android"
    ].has(OS.get_name())

const DEFAULT_USER_SETTINGS: Dictionary = {
    "fullscreen": false
}

static var _user_settings: Dictionary = DEFAULT_USER_SETTINGS.duplicate(true)

static func set_user_setting(setting: String, value: Variant) -> void:
    if setting not in DEFAULT_USER_SETTINGS:
        return
    if setting == "fullscreen":
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED)
    if DEFAULT_USER_SETTINGS[setting] != value:
        _user_settings[setting] = value
    else:
        _user_settings.erase(setting)
    _save_settings()

static func get_user_setting(setting: String) -> Variant:
    if setting in _user_settings:
        return _user_settings[setting]
    elif setting in DEFAULT_USER_SETTINGS:
        return DEFAULT_USER_SETTINGS[setting]
    return null

static func load_settings() -> void:
    if FileAccess.file_exists(Global.SETTINGS_PATH):
        var settings_str: String = FileAccess.get_file_as_string(Global.SETTINGS_PATH)
        var settings_dict: Dictionary = JSON.parse_string(settings_str)
        for prop: String in settings_dict.keys():
            set_user_setting(prop, settings_dict[prop])

static func _save_settings() -> void:
    var settings_str: String = JSON.stringify(_user_settings)
    var s_save: FileAccess = FileAccess.open(Global.SETTINGS_PATH, FileAccess.WRITE)
    s_save.store_string(settings_str)
    s_save.close()

static func setup() -> void:
    load_settings()
    has_setup = true
    ThemeDB.fallback_base_scale = 5.0