extends Control


@onready var config_selector: ConfigSelector = %ConfigSelector
@onready var config_code: CodeEdit = %ConfigCode
@onready var import_config: Button = %ImportConfig
@onready var image_list: VBoxContainer = %ImageList
@onready var import_images_dialog: FileDialog = %ImportImagesDialog
@onready var save_config_dialog: FileDialog = %SaveConfigDialog
@onready var config_name: LineEdit = %ConfigName
@onready var overwrite_dialog: ConfirmationDialog = %OverwriteDialog
@onready var config_loaded_alert: AcceptDialog = %ConfigLoadedAlert
@onready var import_images_label: Label = %ImportImagesLabel


@onready var gallery_image_scene: PackedScene = preload("res://src/scenes/ui/components/gallery_image.tscn")

func _ready() -> void:
    save_config_dialog.filters = PackedStringArray([str("*",Globals.CONFIG_EXTENSION)])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float):
    import_config.disabled = not config_selector.is_selecting_config()
    import_images_label.text = "Imported images (%s)" % image_list.get_child_count()


func _on_back_button_pressed():
    SignalManager.scene_transition.emit("res://src/scenes/menu/main_menu.tscn")

func clear_config() -> void:
    config_code.text = ""
    refresh_images({})
    config_name.text = ""


func refresh_from_loaded(tbt: TabletopGame) -> void:
    if tbt == null:
        clear_config()
        return
    print("Config code setting text")
    config_code.text = tbt.get_script().source_code
    print("Setting images")
    refresh_images(tbt.get_images())
    config_name.text = tbt.name
    config_loaded_alert.popup()

func refresh_images(images: Dictionary) -> void:
    # Remove all previous images
    for i in image_list.get_children():
        i.queue_free()
    
    for key in images.keys():
        var gallery_image: GalleryImage = gallery_image_scene.instantiate()
        gallery_image._set_type(images[key], key)
        image_list.add_child(gallery_image)
        print("Adding image ",key)

func add_images(images: Array) -> void:
    for image in images:
        var gallery_image: GalleryImage = gallery_image_scene.instantiate()
        gallery_image._set_type(image, "untitled")
        image_list.add_child(gallery_image)


func _on_import_configuration_pressed() -> void:
    if config_code.text != "" or config_name.text != "" or not image_list.get_children().is_empty():
        overwrite_dialog.popup()
    else:
        import_config_to_editor()

func import_config_to_editor() -> void:
    print("Getting selected config")
    var current_config: TabletopGame = config_selector.get_selected_config()
    print("Refreshing from loaded")
    refresh_from_loaded(current_config)


func _on_import_images_pressed() -> void:
    import_images_dialog.popup()


func _on_import_images_dialog_files_selected(paths: PackedStringArray) -> void:
    # print("Importing images: ",paths)

    var new_images: Array = Utils.load_images_into_array(paths)
    if new_images.is_empty():
        print("Something went wrong loading images")
        return
    add_images(new_images)


func _on_save_configuration_pressed() -> void:
    save_config_dialog.popup()

func get_src_code() -> String:
    return config_code.text

func get_images() -> Dictionary:
    var res: Dictionary = {}
    for i: GalleryImage in image_list.get_children():
        if i.text in res:
            print("Duplicate name detected! ", i.text)
            return {}
        res[i.text] = i.texture.get_image().save_webp_to_buffer()
    return res

func get_conf_name() -> String:
    return config_name.text

func export_data() -> PackedByteArray:
    var src_code: String = get_src_code()
    var images: Dictionary = get_images()
    var conf_name: String = get_conf_name()
    if conf_name == "" or images.is_empty() or src_code == "":
        print("Config static validation failed")
        return []
    var bytes: PackedByteArray = TabletopGame.export_config(src_code, images, conf_name)
    if bytes.is_empty():
        print("Problem creating %s config" % Globals.CONFIG_EXTENSION)
        return []
    return bytes

func _on_save_config_dialog_file_selected(path: String) -> void:
    if path.rfind(Globals.CONFIG_EXTENSION) != len(path) - len(Globals.CONFIG_EXTENSION):
        print("Adding file extension")
        path = path + Globals.CONFIG_EXTENSION
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
