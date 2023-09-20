extends FileDialog

func _ready() -> void:
    SignalManager.create_load_config_dialog.connect(import_config)
    file_selected.connect(filepath_selected)

func import_config() -> void:
    title = "Import a config"
    popup()

func filepath_selected(fname: String) -> void:
    print(fname)
    if FileAccess.file_exists(fname):
        file_decided(FileAccess.get_file_as_bytes(fname))
    else:
        print("File at ",fname, " doesn't exist!")
    
func file_decided(buf: PackedByteArray) -> void:
    print("Importing config")
    var config: TabletopGame = TabletopGame.import_config(buf)
    
    Utils.FileManager.create_dir(Globals.CONFIG_REPO)

    var conf_path: String = str(Globals.CONFIG_REPO, "/",config.name,Globals.CONFIG_EXTENSION)

    Utils.FileManager.delete_file(conf_path)
    
    var local_copy: FileAccess = FileAccess.open(conf_path, FileAccess.WRITE)

    if local_copy == null:
        print(FileAccess.get_open_error(), ": ", conf_path)
        return

    local_copy.store_buffer(buf)
    local_copy.close()
    print("Done! Sent to ",conf_path)
    SignalManager.config_added.emit()

