extends FileDialog

var config: Resource = null

func _ready() -> void:
	SignalManager.export_conf.connect(_on_config_created)
	file_selected.connect(_on_file_decided)
	filters = ["*.obf.res"]

func _on_config_created(conf: Resource) -> void:
	config = conf
	popup()

func _on_file_decided(fpath: String) -> void:
	var result: int = ResourceSaver.save(config, fpath, 0x20)
	print("Finished exporting with code ",result)
