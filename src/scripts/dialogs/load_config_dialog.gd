extends FileDialog


func _ready() -> void:
    SignalManager.create_load_config_dialog.connect(_on_create_load_config)
    file_selected.connect(_on_file_decided)
    # filters = ["*.obf.res"]

func _on_create_load_config() -> void:
    popup()

func _on_file_decided(fname: String) -> void:
    Globals.get_tabletop().load_config(ResourceLoader.load(fname, ""))

