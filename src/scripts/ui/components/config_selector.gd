class_name ConfigSelector
extends Control

@onready var config_list: ItemList = %ConfigList
@onready var delete_button: Button = %DeleteSelected
@onready var from_file_button: Button = %LoadConfFile

func _ready() -> void:
    SignalManager.config_added.connect(config_added)
    Globals.load_this_game = PackedByteArray([])
    refresh_list()
    if not Utils.is_desktop_platform():
        from_file_button.hide()

func _process(_delta: float) -> void:
    delete_button.disabled = not is_selecting_config() or is_selecting_default_config()

func config_added() -> void:
    %ImportConfigNotice.popup()
    await %ImportConfigNotice.visibility_changed
    %ImportConfigNotice.hide()
    refresh_list()

func refresh_list() -> void:
    config_list.clear()
    config_list.add_item("Default Config")
    for conf: String in Utils.FileManager.get_available_configs():
        config_list.add_item(conf)


func _on_load_conf_file_pressed() -> void:
    SignalManager.create_load_config_dialog.emit()

func _on_refresh_conf_list_pressed() -> void:
    refresh_list()

func get_currently_selected_config() -> String:
    return config_list.get_item_text(config_list.get_selected_items()[0])

func is_selecting_config() -> bool:
    return not config_list.get_selected_items().is_empty()

func is_selecting_default_config() -> bool:
    return is_selecting_config() and config_list.get_selected_items()[0] == 0

func get_config_file_path(conf_name: String) -> String:
    return str(Globals.CONFIG_REPO,"/",conf_name,Globals.CONFIG_EXTENSION)

func _on_delete_selected_pressed() -> void:
    if is_selecting_config() and not is_selecting_default_config():
        var currently_selected: String = get_currently_selected_config()
        Utils.FileManager.delete_file(get_config_file_path(currently_selected))
        # print("File deleted")
        refresh_list()

func _on_load_conf_url_pressed() -> void:
    SignalManager.download_config_popup.emit()

func get_selected_config_bytes() -> PackedByteArray:
    if is_selecting_config():
        if is_selecting_default_config():
            print("Getting default config")
            return Utils.FileManager.get_file_bytes(Globals.DEFAULT_CONFIG_PATH)
        else:
            print("Getting given config")
            return Utils.FileManager.get_file_bytes(get_config_file_path(get_currently_selected_config()))
    return []

func get_selected_config() -> TabletopGame:
    var _bytes = get_selected_config_bytes()
    if _bytes.is_empty():
        return null
    return TabletopGame.import_config(_bytes)