extends FileDialog


func _ready() -> void:
    SignalManager.create_load_config_dialog.connect(_on_create_load_config)
    dir_selected.connect(_on_directory_decided)

func _on_create_load_config() -> void:
    popup()

func _on_directory_decided(dir: String) -> void:
    SignalManager.config_folder_opened.emit(dir)

