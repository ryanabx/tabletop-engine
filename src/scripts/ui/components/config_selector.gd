class_name ConfigSelector
extends Control

@onready var config_list: ItemList = %ConfigList
@onready var delete_button: Button = %DeleteSelected
@onready var from_file_button: Button = %LoadConfFile

var num_default_configs: int = 0

func _ready() -> void:
    Global.load_this_game = PackedByteArray([])
    refresh_list()
    %ImportConfigFile.file_selected.connect(add_from_filepath)
    if not Global.is_desktop_platform():
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
    var default_configs: Array[String] = get_available_configs(Global.DEFAULT_CONFIG_REPO)
    num_default_configs = default_configs.size()
    for conf: String in default_configs:
        config_list.add_item(conf)
    for conf: String in get_available_configs(Global.CONFIG_REPO):
        config_list.add_item(conf)

func get_available_configs(path: String) -> Array[String]:
    if not DirAccess.dir_exists_absolute(path):
        print("Directory doesn't exist!")
        return []
    
    var configs: Array[String] = []

    var directory: DirAccess = DirAccess.open(path)

    for fname: String in directory.get_files():
        var split_fname: PackedStringArray = fname.rsplit(".",1)
        if fname.rsplit(".",1)[-1] == Global.CONFIG_EXTENSION.substr(1):
            configs.append(split_fname[0])
    
    return configs

func _on_load_conf_file_pressed() -> void:
    %ImportConfigFile.popup()

func _on_refresh_conf_list_pressed() -> void:
    refresh_list()

func get_currently_selected_config() -> String:
    return config_list.get_item_text(config_list.get_selected_items()[0])

func is_selecting_config() -> bool:
    return not config_list.get_selected_items().is_empty()

func is_selecting_default_config() -> bool:
    return is_selecting_config() and config_list.get_selected_items()[0] < num_default_configs

func get_config_file_path(conf_name: String, conf_dir: String) -> String:
    return str(conf_dir,"/",conf_name,Global.CONFIG_EXTENSION)

func _on_delete_selected_pressed() -> void:
    if is_selecting_config() and not is_selecting_default_config():
        var currently_selected: String = get_currently_selected_config()
        DirAccess.remove_absolute(get_config_file_path(currently_selected, Global.CONFIG_REPO))
        refresh_list()

func _on_load_conf_url_pressed() -> void:
    %DownloadConfigPanel.popup()

func get_selected_config_bytes() -> PackedByteArray:
    if is_selecting_config():
        if is_selecting_default_config():
            print("Getting default config")
            return get_file_bytes(get_config_file_path(get_currently_selected_config(), Global.DEFAULT_CONFIG_REPO))
        else:
            print("Getting given config")
            return get_file_bytes(get_config_file_path(get_currently_selected_config(), Global.CONFIG_REPO))
    return []

func get_file_bytes(fname: String) -> PackedByteArray:
    if FileAccess.file_exists(fname):
        var bytes: PackedByteArray = FileAccess.get_file_as_bytes(fname)
        return bytes
    else:
        print("Could not find file ", fname)
    return PackedByteArray([])

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
    if FileAccess.file_exists(fname):
        file_decided(FileAccess.get_file_as_bytes(fname))
    else:
        print("File at ",fname, " doesn't exist!")
    
func file_decided(buf: PackedByteArray) -> void:
    print("Importing config")
    if ConfigSelector.save_config_to_file(buf):
        config_added()

static func save_config_to_file(buf: PackedByteArray) -> bool:
    var config: TabletopGame = TabletopGame.import_config(buf)
    
    DirAccess.make_dir_absolute(Global.CONFIG_REPO)

    var conf_path: String = str(Global.CONFIG_REPO, "/",config.name,Global.CONFIG_EXTENSION)

    DirAccess.remove_absolute(conf_path)
    
    var local_copy: FileAccess = FileAccess.open(conf_path, FileAccess.WRITE)

    if local_copy == null:
        print(FileAccess.get_open_error(), ": ", conf_path)
        return false

    local_copy.store_buffer(buf)
    local_copy.close()
    print("Done! Sent to ",conf_path)
    return true

static func config_exists(conf_name: String) -> bool:
    return FileAccess.file_exists(str(Global.CONFIG_REPO, "/",conf_name,Global.CONFIG_EXTENSION))

# Download config from URL

func _download_url_about_to_popup() -> void:
    %URLEdit.text = ""

func _on_url_cancel_pressed() -> void:
    %DownloadConfigPanel.hide()

func _on_download_config_pressed() -> void:
    if await download_file_from_url(%URLEdit.text):
        config_added()
        %DownloadConfigPanel.hide()

func _on_paste_link_pressed() -> void:
    %URLEdit.text = DisplayServer.clipboard_get()

# Previously in Global.FileManager...

func download_file_from_url(url: String) -> bool:
        var file: PackedByteArray = await download_file(url)
        if file.is_empty():
            print("Could not download file from url ",url)
            return false
        return validate_downloaded_file(file)

func download_file(url: String) -> PackedByteArray:
    var request: HTTPRequest = HTTPRequest.new()
    add_child(request)
    var res: int = request.request(url)
    if res != OK:
        request.queue_free()
        print("Error when making httprequest: ", res)
        return []
    print("Downloading ", request.get_body_size(), " bytes from ", url)
    var result: Array = await request.request_completed
    print("Download completed: ",result)
    request.queue_free()
    if result[1] == 303:
        var new_url: String = result[2][5].split("Location: ", false, 1)[0]
        print("303 ERROR, going to url ", new_url)
        return await download_file(new_url)
    return PackedByteArray(result[4])

func validate_downloaded_file(file: PackedByteArray) -> bool:
    if file.is_empty():
        print("Config was empty")
        return false
    var conf: TabletopGame = TabletopGame.import_config(file)
    var conf_path: String = str(Global.CONFIG_REPO, "/",conf.name,Global.CONFIG_EXTENSION)
    DirAccess.remove_absolute(conf_path)
    var local_copy: FileAccess = FileAccess.open(conf_path, FileAccess.WRITE)
    if local_copy == null:
        print(FileAccess.get_open_error(), ": ", conf_path)
        return false
    local_copy.store_buffer(conf.to_bytes())
    local_copy.close()
    return true

func _on_download_config_panel_close_requested() -> void:
    %DownloadConfigPanel.hide()


func _on_import_config_file_close_requested() -> void:
    %ImportConfigFile.hide()
