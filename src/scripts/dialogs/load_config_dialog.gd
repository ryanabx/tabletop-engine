extends FileDialog


func _ready() -> void:
	SignalManager.create_load_config_dialog.connect(_on_create_load_config)
	file_selected.connect(_on_file_decided)
	filters = ["*.obf.res"]

func _on_create_load_config() -> void:
	title = "Load a config of your choice!"
	popup()

func _on_file_decided(fname: String) -> void:
	SignalManager.load_game_config.emit(ResourceLoader.load(fname, ""))
	dialog_text = ""

