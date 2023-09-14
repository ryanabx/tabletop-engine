extends Node

var req: HTTPRequest

func _ready() -> void:
    req = HTTPRequest.new()
    add_child(req)

func load_images_into_array(image_strings: Array, image_directory: String) -> Array:
    var result: Array = []
    for image_path: String in image_strings:
        var _image := Image.new()
        var _err := _image.load(image_directory + image_path)
        if _err != OK:
            print("Failed to load image: ",image_directory + image_path)
            return []
        var _texture := ImageTexture.new()
        _texture = ImageTexture.create_from_image(_image)
        result.append(_texture)
    return result

func load_texture_from_string(fname: String, image_directory: String) -> Texture2D:
    var _image := Image.new()
    var _err := _image.load(image_directory + fname)
    if _err != OK:
        print("Failed to load image: ",image_directory + fname)
        return null
    var _texture := ImageTexture.new()
    _texture = ImageTexture.create_from_image(_image)
    return _texture

func rect_with_padding(rct: Rect2, padding: float) -> Rect2:
    return Rect2(rct.position - Vector2(padding, padding), rct.size + Vector2(padding * 2, padding * 2))

func load_json_from_file(fname: String) -> Dictionary:
    if FileAccess.file_exists(fname):
        var data_file := FileAccess.open(fname, FileAccess.READ)
        var parsed_result: Variant = JSON.parse_string(data_file.get_as_text())
        if parsed_result is Dictionary:
            return parsed_result
        else:
            print("Error parsing file: ",fname)
            return {}
    else:
        print("File not found: ",fname)
        return {}

func random_string(length: int) -> String:
    return generate_word(Globals.CODE_CHARS, length)

func generate_word(chars: String, length: int) -> String:
    var word: String = ""
    var n_char := len(chars)
    for i: int in range(length):
        word += chars[randi()% n_char]
    return word

func load_images_from_directory(dir: String) -> Dictionary:
    var textures: Dictionary = {}
    var directory_access := DirAccess.open(dir)
    if directory_access.dir_exists("."):
        for fname: String in directory_access.get_files():
            var file_ext: String = fname.rsplit(".")[-1]
            if file_ext in ["png", "jpg", "jpeg", "bmp", "svg"]:
                var _tx := load_texture_from_string(fname, str(dir,"/"))
                if _tx != null:
                    textures[fname] = _tx
    return textures

func has_any(arr1: Array[Variant], arr2: Array[Variant]) -> bool:
    for x: Variant in arr1:
        for y: Variant in arr2:
            if x == y:
                return true
    return false

@rpc("any_peer", "call_remote", "reliable")
func go_to_scene(fpath: String) -> void:
    SignalManager.scene_transition.emit(fpath)


class FileManager:
    ## Compresses dictionary through Gzip compression
    static func compress_dictionary(_dict: Dictionary) -> PackedByteArray:
        return var_to_bytes(JSON.stringify(_dict)).compress(3)
    
    ## Decompresses dictionary through Gzip decompression
    static func decompress_to_dictionary(_bytes: PackedByteArray) -> Dictionary:
        return JSON.parse_string(bytes_to_var(_bytes.decompress_dynamic(-1, 3)))
    
    ## Gets string from bytes
    static func decode_string(_bytes: PackedByteArray) -> String:
        return Marshalls.raw_to_base64(_bytes)
    
    ## Gets bytes from string
    static func encode_string(_string: String) -> PackedByteArray:
        return Marshalls.base64_to_raw(_string)

    static func create_dir(dir: String) -> void:
        if DirAccess.dir_exists_absolute(dir):
            return
        
        DirAccess.make_dir_absolute(dir)

    static func get_available_configs() -> Array[String]:
        if not DirAccess.dir_exists_absolute(Globals.CONFIG_REPO):
            print("Directory doesn't exist!")
            return []
        
        var configs: Array[String] = []

        var directory: DirAccess = DirAccess.open(Globals.CONFIG_REPO)

        for fname: String in directory.get_files():
            var split_fname: PackedStringArray = fname.rsplit(".",1)
            print(split_fname[0], ", ", split_fname[1])
            if fname.rsplit(".",1)[-1] == Globals.CONFIG_EXTENSION.substr(1):
                configs.append(split_fname[0])
        
        return configs

    static func delete_file(fname: String) -> void:
        if FileAccess.file_exists(fname):
            DirAccess.remove_absolute(fname)

    static func get_file_bytes(fname: String) -> PackedByteArray:
        if FileAccess.file_exists(fname):
            var bytes: PackedByteArray = FileAccess.get_file_as_bytes(fname)
            return bytes
        else:
            print("Could not find file ", fname)
        return PackedByteArray([])

    static func download_file_from_url(url: String) -> bool:
        var fpath: String = await download_file(url)
        if fpath == "":
            print("Could not download file from url ",url)
            return false
        
        return validate_downloaded_file(fpath)

    static func download_file(url: String) -> String:
        var req: HTTPRequest = Utils.req
        req.download_file = Globals.DOWNLOAD_FILE_PATH
        var res: int = req.request(url)
        if res != OK:
            req.queue_free()
            print("Error when making httprequest: ", res)
            return ""
        print("Downloading ", req.get_body_size(), " bytes from ", url)
        var result: Array = await req.request_completed
        print("Download completed: ",result)
        req.queue_free()
        if result[1] == 303:
            var new_url: String = result[2][5].split("Location: ", false, 1)[0]
            print("303 ERROR, going to url ", new_url)
            return await download_file(new_url)
        req.download_file = ""
        return Globals.DOWNLOAD_FILE_PATH

    static func validate_downloaded_file(fpath: String) -> bool:
        var bytes: PackedByteArray = get_file_bytes(fpath)
        if bytes.is_empty():
            print("Config was null")
            delete_file(fpath)
            return false
        print("Looking for fpath ",fpath)
        create_dir(Globals.CONFIG_REPO)
        var conf: TabletopGame = TabletopGame.import_config(bytes)

        var conf_path: String = str(Globals.CONFIG_REPO, "/",conf.export_settings().name,Globals.CONFIG_EXTENSION)

        Utils.delete_file(conf_path)
        
        var local_copy: FileAccess = FileAccess.open(conf_path, FileAccess.WRITE)
        

        if local_copy == null:
            print(FileAccess.get_open_error(), ": ", conf_path)
            return false

        local_copy.store_buffer(conf.to_bytes())
        local_copy.close()
        
        delete_file(fpath)
        return true

var current_safe_area: Rect2i = Rect2i(0, 0, 0, 0)

func is_desktop_platform() -> bool:
    return [
        "Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"
    ].has(OS.get_name())

func is_web_platform() -> bool:
    return [
        "Web"
    ].has(OS.get_name())

func is_mobile_platform() -> bool:
    return [
        "iOS", "Android"
    ].has(OS.get_name())

func on_screen_orientation_changed() -> void:
    var w_size: Vector2i = DisplayServer.screen_get_size(DisplayServer.get_primary_screen())
    var orientation_extents: Rect2i = DisplayServer.get_display_safe_area()
    
    var margin_l: int = orientation_extents.position.x
    var margin_t: int = orientation_extents.position.y
    var margin_r: int = w_size.x - orientation_extents.size.x - margin_l
    var margin_b: int = w_size.y - orientation_extents.size.y - margin_t
    Globals.safe_margin_l = margin_l
    Globals.safe_margin_t = margin_t
    Globals.safe_margin_r = margin_r
    Globals.safe_margin_b = margin_b
    current_safe_area = DisplayServer.get_display_safe_area()
    SignalManager.orientation_changed.emit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    if Utils.current_safe_area != DisplayServer.get_display_safe_area():
        Utils.on_screen_orientation_changed()
    
    # if multiplayer.multiplayer_peer is WebRTCMultiplayerPeer:
    #     multiplayer.poll()
