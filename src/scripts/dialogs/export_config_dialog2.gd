extends FileDialog

var config: PackedByteArray = []

func _ready() -> void:
	SignalManager.export_conf.connect(_on_config_created)
	file_selected.connect(_on_file_decided)
	filters = ["*.obgf"]

func _on_config_created(conf: PackedByteArray) -> void:
	config = conf
	popup()

func _on_file_decided(fpath: String) -> void:
	var f = FileAccess.open(fpath, FileAccess.WRITE)
	f.store_buffer(config)
	f.close()
	print("Finished config")
