class_name ConfigSelector
extends Control

@onready var config_list: ItemList = %ConfigList
@onready var delete_button: Button = %DeleteSelected
@onready var from_file_button: Button = %LoadConfFile

func _ready() -> void:
    Global.load_this_game = PackedByteArray([])
    refresh_list()
    %ImportConfigFile.file_selected.connect(add_from_filepath)
    if not Utils.is_desktop_platform():
        from_file_button.hide()

func _process(_delta: float) -> void:
    delete_button.disabled = not is_selecting_config() or is_selecting_default_config()
    %DownloadConfig.disabled = (%URLEdit.text == "")

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
    %ImportConfigFile.popup()

func _on_refresh_conf_list_pressed() -> void:
    refresh_list()

func get_currently_selected_config() -> String:
    return config_list.get_item_text(config_list.get_selected_items()[0])

func is_selecting_config() -> bool:
    return not config_list.get_selected_items().is_empty()

func is_selecting_default_config() -> bool:
    return is_selecting_config() and config_list.get_selected_items()[0] == 0

func get_config_file_path(conf_name: String) -> String:
    return str(Global.CONFIG_REPO,"/",conf_name,Global.CONFIG_EXTENSION)

func _on_delete_selected_pressed() -> void:
    if is_selecting_config() and not is_selecting_default_config():
        var currently_selected: String = get_currently_selected_config()
        Utils.FileManager.delete_file(get_config_file_path(currently_selected))
        refresh_list()

func _on_load_conf_url_pressed() -> void:
    %DownloadConfigPanel.popup()

func get_selected_config_bytes() -> PackedByteArray:
    if is_selecting_config():
        if is_selecting_default_config():
            print("Getting default config")
            return Utils.FileManager.get_file_bytes(Global.DEFAULT_CONFIG_PATH)
        else:
            print("Getting given config")
            return Utils.FileManager.get_file_bytes(get_config_file_path(get_currently_selected_config()))
    return []

func get_config_data() -> Dictionary:
    var _bytes := get_selected_config_bytes()
    if _bytes.is_empty():
        return {}
    var config: Dictionary = bytes_to_var(_bytes.decompress_dynamic(-1, 3))
    return config

func get_selected_config() -> TabletopGame:
    var _bytes := get_selected_config_bytes()
    if _bytes.is_empty():
        return null
    return TabletopGame.import_config(_bytes)

# Import config file dialog

func add_from_filepath(fname: String) -> void:
    print(fname)
    if FileAccess.file_exists(fname):
        file_decided(FileAccess.get_file_as_bytes(fname))
    else:
        print("File at ",fname, " doesn't exist!")
    
func file_decided(buf: PackedByteArray) -> void:
    print("Importing config")
    var config: TabletopGame = TabletopGame.import_config(buf)
    
    Utils.FileManager.create_dir(Global.CONFIG_REPO)

    var conf_path: String = str(Global.CONFIG_REPO, "/",config.name,Global.CONFIG_EXTENSION)

    Utils.FileManager.delete_file(conf_path)
    
    var local_copy: FileAccess = FileAccess.open(conf_path, FileAccess.WRITE)

    if local_copy == null:
        print(FileAccess.get_open_error(), ": ", conf_path)
        return

    local_copy.store_buffer(buf)
    local_copy.close()
    print("Done! Sent to ",conf_path)
    config_added()

# Download config from URL

func _download_url_about_to_popup() -> void:
    %URLEdit.text = ""

func _on_url_cancel_pressed() -> void:
    %DownloadConfigPanel.hide()

func _on_download_config_pressed() -> void:
    if await Utils.FileManager.download_file_from_url(%URLEdit.text):
        config_added()
        %DownloadConfigPanel.hide()

func _on_paste_link_pressed() -> void:
    %URLEdit.text = DisplayServer.clipboard_get()