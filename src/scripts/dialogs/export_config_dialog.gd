extends FileDialog

func _ready() -> void:
	SignalManager.create_export_config_dialog.connect(_on_create_export_config)
	file_selected.connect(_on_folder_decided)
	filters = ["*.json"]

func _on_create_export_config() -> void:
	popup()

func _on_folder_decided(fpath: String) -> void:
	var game_config: PackedByteArray = GameConfig2.export_config_from_file(fpath)
	hide()
	SignalManager.export_conf.emit(game_config)
