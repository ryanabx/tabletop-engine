extends Control

@onready var config_selector: ConfigSelector = %ConfigSelector
@onready var config_code: CodeEdit = %ConfigCode
@onready var import_config: Button = %ImportConfig
@onready var image_list: VBoxContainer = %ImageList
@onready var import_images_dialog: FileDialog = %ImportImagesDialog
@onready var save_config_dialog: FileDialog = %SaveConfigDialog
@onready var config_name: LineEdit = %ConfigName
@onready var overwrite_dialog: Window = %OverwriteDialog
@onready var config_loaded_alert: Window = %ConfigLoadedAlert
@onready var import_images_label: Label = %ImportImagesLabel

@onready var gallery_image_scene: PackedScene = preload("res://src/scenes/ui/components/gallery_image.tscn")

func _ready() -> void:
    save_config_dialog.filters = PackedStringArray([str("*",Global.CONFIG_EXTENSION)])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    import_config.disabled = not config_selector.is_selecting_config()
    import_images_label.text = "Imported images (%s)" % image_list.get_child_count()

func _on_back_button_pressed() -> void:
    ($FadeRect as FadeRect).scene_transition.emit("res://src/scenes/ui/pages/main_menu.tscn")

func clear_config() -> void:
    config_code.text = ""
    refresh_images({})
    config_name.text = ""

func refresh_from_loaded(tbt: Dictionary) -> void:
    if tbt == null:
        clear_config()
        return
    print("Config code setting text")
    config_code.text = tbt.script
    print("Setting images")
    var include_images: Dictionary = tbt.include_images
    refresh_images(include_images)
    config_name.text = tbt.name
    config_loaded_alert.popup()

func refresh_images(imgs: Dictionary) -> void:
    # Remove all previous images
    for i: Node in image_list.get_children():
        i.queue_free()
    # Add new images
    for img: String in imgs.keys():
        var n_img: Image = Image.new()
        var buf: PackedByteArray = imgs[img]
        n_img.load_webp_from_buffer(buf)
        var gallery_image: GalleryImage = gallery_image_scene.instantiate()
        gallery_image._set_type(ImageTexture.create_from_image(n_img), img)
        image_list.add_child(gallery_image)

func add_images(result: Dictionary) -> void:
    for key: String in result.keys():
        var gallery_image: GalleryImage = gallery_image_scene.instantiate()
        var texture: Texture2D = result[key]
        gallery_image._set_type(texture, key)
        image_list.add_child(gallery_image)

func _on_import_configuration_pressed() -> void:
    if config_code.text != "" or config_name.text != "" or not image_list.get_children().is_empty():
        overwrite_dialog.popup()
    else:
        import_config_to_editor()

func import_config_to_editor() -> void:
    print("Getting selected config")
    var current_config: Dictionary = config_selector.get_config_data()
    print("Refreshing from loaded")
    refresh_from_loaded(current_config)


func _on_import_images_pressed() -> void:
    import_images_dialog.popup()


func _on_import_images_dialog_files_selected(paths: PackedStringArray) -> void:
    # print("Importing images: ",paths)
    add_images(load_images_into_dict(paths))

func load_images_into_dict(paths: PackedStringArray) -> Dictionary:
    var result: Dictionary = {}
    for path: String in paths:
        var img_name: String = path.simplify_path().rsplit("/",false,1)[-1].rsplit(".",false,1)[0]
        print(img_name)
        var img: Image = Image.load_from_file(path)
        var texture: ImageTexture = ImageTexture.create_from_image(img)
        result[img_name] = texture
    return result

func _on_save_configuration_pressed() -> void:
    save_config_dialog.popup()

func get_src_code() -> String:
    return config_code.text

func get_images() -> Dictionary:
    var res: Dictionary = {}
    for i: GalleryImage in image_list.get_children():
        if i.text in res:
            print("Duplicate name detected! ", i.text)
            return {"empty": true}
        res[i.text] = i.texture.get_image().save_webp_to_buffer()
    return res

func get_conf_name() -> String:
    return config_name.text

func export_data() -> PackedByteArray:
    var src_code: String = get_src_code()
    var images: Dictionary = get_images()
    var conf_name: String = get_conf_name()
    if conf_name == "" or ("empty" in images and images["empty"] == true) or src_code == "":
        print("Config static validation failed")
        return []
    var bytes: PackedByteArray = TabletopGame.export_config(src_code, images, conf_name)
    if bytes.is_empty():
        print("Problem creating %s config" % Global.CONFIG_EXTENSION)
        return []
    return bytes

func _on_save_config_dialog_file_selected(path: String) -> void:
    if path.rfind(Global.CONFIG_EXTENSION) != len(path) - len(Global.CONFIG_EXTENSION):
        print("Adding file extension")
        path = path + Global.CONFIG_EXTENSION
    print("File selected! ",path)
    var bytes: PackedByteArray = export_data()
    if bytes.is_empty():
        return
    var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    f.store_buffer(bytes)
    f.close()
    print("Config created at ", path)

func _on_overwrite_dialog_confirmed() -> void:
    import_config_to_editor()

func _on_import_code_dialog_file_selected(path:String) -> void:
    var code: String = FileAccess.get_file_as_string(path)
    config_code.text = code


func _on_import_code_pressed() -> void:
    (%ImportCodeDialog as Window).popup()
