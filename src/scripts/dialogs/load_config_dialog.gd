extends FileDialog


func _ready() -> void:
    SignalManager.create_load_config_dialog.connect(_on_create_load_config)
    file_selected.connect(_on_file_decided)
    filters = ["*.json"]

func _on_create_load_config() -> void:
    popup()

func _on_file_decided(fname: String) -> void:
    SignalManager.config_file_opened.emit(fname)

