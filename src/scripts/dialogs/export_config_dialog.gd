extends FileDialog

func _ready() -> void:
	SignalManager.create_export_config_dialog.connect(_on_create_export_config)
	dir_selected.connect(_on_folder_decided)
	# filters = ["*.obf"]

func _on_create_export_config() -> void:
	popup()

func _on_folder_decided(fpath: String) -> void:
	var game_config: GameConfig = GameConfig.build_config_from_directory(fpath)
	var result: int = ResourceSaver.save(game_config, "user://config.obf.res", 0x20)
	print("Finished exporting with code ",result)